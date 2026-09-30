#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <math.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#if !defined(__aarch64__)
#error "Build for AArch64 Linux"
#endif
#if defined(__FAST_MATH__)
#error "Do not build with -ffast-math"
#endif

typedef struct {
    int dim, hidden_dim, n_layers, n_heads;
    int n_kv_heads, vocab_size, seq_len;
} Config;

_Static_assert(sizeof(Config) == 28, "Unexpected run.c Config layout");
_Static_assert(sizeof(float) == 4, "FP32 is required");

#define CSR_BASE   UINT64_C(0x20023000)
#define FIXED_BASE UINT64_C(0x20020000)
#define DDR_BASE   UINT64_C(0x20021000)
#define FP32_BASE  UINT64_C(0x20022000)

#define SHARED_LO UINT64_C(0xB8000000)
#define SHARED_HI UINT64_C(0xC0000000)
#define W_PHYS    UINT64_C(0xB8000040)
#define X_PHYS    UINT64_C(0xBFF00000)
#define Y_PHYS    UINT64_C(0xBFF10000)

#define GUARD_WORDS 16
#define POISON UINT32_C(0x7FC00000)
#define TIMEOUT_MS UINT64_C(60000)

enum {
    CTRL = 0x00, STATUS = 0x04,
    W_LO = 0x08, W_HI = 0x0C,
    X_LO = 0x10, X_HI = 0x14,
    Y_LO = 0x18, Y_HI = 0x1C,
    CYCLES = 0x20, VERSION = 0x24, DEBUG = 0x28,
    ROWS = 0x2C, COLS = 0x30,
    MAX_ROWS = 0x34, MAX_COLS = 0x38,
    ROW_INDEX = 0x3C, COL_INDEX = 0x40
};

typedef struct {
    volatile uint32_t *all;
    volatile uint32_t *data;
    size_t words;
    uint64_t start, end;
} Region;

static int in_flight;
static volatile sig_atomic_t interrupted;

static void on_signal(int sig)
{
    (void)sig;
    interrupted = 1;
}

static void die(const char *message)
{
    fprintf(stderr, "[FAIL] %s\n", message);
    if (in_flight)
        fprintf(stderr, "FPGA completion is unconfirmed; do not "
                        "reuse DDR, CLEAR, or retry START.\n");
    exit(EXIT_FAILURE);
}

static void barrier(void)
{
    __asm__ volatile("dsb sy" ::: "memory");
}

static uint32_t bits(float f)
{
    uint32_t u;
    memcpy(&u, &f, sizeof(u));
    return u;
}

static float value(uint32_t u)
{
    float f;
    memcpy(&f, &u, sizeof(f));
    return f;
}

static uint32_t read_reg(volatile uint32_t *csr, unsigned offset)
{
    uint32_t result;
    barrier();
    result = csr[offset / 4];
    barrier();
    return result;
}

static void write_reg(volatile uint32_t *csr,
                      unsigned offset, uint32_t value)
{
    barrier();
    csr[offset / 4] = value;
    barrier();
}

static uint64_t now_ms(void)
{
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t) != 0)
        die("clock_gettime failed");
    return (uint64_t)t.tv_sec * 1000 + t.tv_nsec / 1000000;
}

static void check_cmdline(void)
{
    char line[4096];
    FILE *f = fopen("/proc/cmdline", "r");
    int found = 0;

    if (!f || !fgets(line, sizeof(line), f))
        die("Cannot read /proc/cmdline");
    fclose(f);

    for (char *p = strtok(line, " \t\n"); p;
         p = strtok(NULL, " \t\n")) {
        if (strncmp(p, "mem=", 4) == 0) {
            if (strcmp(p, "mem=896M") != 0)
                die("Unexpected mem= boot argument");
            ++found;
        }
    }
    if (found != 1)
        die("Require exactly one mem=896M boot argument");
}

static void pread_exact(int fd, void *dst, size_t len, uint64_t offset)
{
    unsigned char *p = dst;
    while (len) {
        ssize_t n = pread(fd, p, len, (off_t)offset);
        if (n <= 0)
            die("Checkpoint is truncated or pread failed");
        p += n;
        len -= (size_t)n;
        offset += (uint64_t)n;
    }
}

static void check_file_range(uint64_t offset, uint64_t length,
                             uint64_t file_size)
{
    if (offset > file_size || length > file_size - offset)
        die("Checkpoint section extends past file end");
}

static volatile uint32_t *map_phys(int fd, uint64_t phys, size_t bytes)
{
    long page_size = sysconf(_SC_PAGESIZE);
    uint64_t aligned, delta;
    size_t length;
    void *mapping;

    if (page_size <= 0 || (page_size & (page_size - 1)) != 0)
        die("Unexpected page size");
    aligned = phys & ~((uint64_t)page_size - 1);
    delta = phys - aligned;
    length = (size_t)((delta + bytes + page_size - 1) &
                      ~((uint64_t)page_size - 1));

    mapping = mmap(NULL, length, PROT_READ | PROT_WRITE,
                   MAP_SHARED, fd, (off_t)aligned);
    if (mapping == MAP_FAILED)
        die("Cannot mmap /dev/mem region");
    return (volatile uint32_t *)((unsigned char *)mapping + delta);
}

static Region map_region(int fd, uint64_t phys, size_t words)
{
    Region r;
    uint64_t length = (uint64_t)words * 4 + 128;

    r.start = phys - 64;
    r.end = r.start + length;
    if (r.start < SHARED_LO || r.end > SHARED_HI)
        die("DDR buffer/guards outside shared area");

    r.all = map_phys(fd, r.start, (size_t)length);
    r.data = r.all + GUARD_WORDS;
    r.words = words;
    return r;
}

static void check_separate(Region a, Region b)
{
    if (a.start < b.end && b.start < a.end)
        die("DDR test buffers overlap");
}

static uint32_t guard_word(unsigned region, unsigned index, int after)
{
    return UINT32_C(0x13579BDF) ^
           (region << 24) ^ (index * UINT32_C(0x9E3779B9)) ^
           (after ? UINT32_C(0xFFFF0000) : 0);
}

static void set_guards(Region r, unsigned which)
{
    for (unsigned i = 0; i < GUARD_WORDS; ++i) {
        r.all[i] = guard_word(which, i, 0);
        r.data[r.words + i] = guard_word(which, i, 1);
    }
}

static void check_guards(Region r, unsigned which)
{
    for (unsigned i = 0; i < GUARD_WORDS; ++i) {
        if (r.all[i] != guard_word(which, i, 0) ||
            r.data[r.words + i] != guard_word(which, i, 1))
            die("DDR guard corrupted");
    }
}

static void require_idle(volatile uint32_t *var,
                         volatile uint32_t *fixed,
                         volatile uint32_t *ddr,
                         volatile uint32_t *fp32)
{
    if ((read_reg(var, STATUS) & 1) ||
        (read_reg(fixed, STATUS) & 1) ||
        (read_reg(ddr, STATUS) & 1) ||
        (read_reg(fp32, STATUS) & 1))
        die("A test component is BUSY; stop other DDR users");
}

static void set_address(volatile uint32_t *csr,
                        unsigned low_offset, uint64_t addr)
{
    write_reg(csr, low_offset, (uint32_t)addr);
    write_reg(csr, low_offset + 4, (uint32_t)(addr >> 32));
    if (read_reg(csr, low_offset) != (uint32_t)addr ||
        read_reg(csr, low_offset + 4) != (uint32_t)(addr >> 32))
        die("Address CSR readback mismatch");
}

static uint32_t ordered_bits(uint32_t u)
{
    return (u & UINT32_C(0x80000000)) ?
           ~u : (u ^ UINT32_C(0x80000000));
}

int main(int argc, char **argv)
{
    int model_fd, mem_fd, lock_fd;
    struct stat st;
    Config c;
    uint64_t vocab, file_size, embed_offset, rms_offset, wq_offset;
    size_t dim, count;
    unsigned token = 1;
    float *embedding, *norm_weight, *x, *w, *reference;
    Region wr, xr, yr;
    volatile uint32_t *csr, *fixed, *ddr, *fp32;
    uint64_t start;
    uint32_t status, exact = 0, bad = 0, max_ulp = 0;
    double max_abs = 0.0, max_rel = 0.0;
    struct sigaction action = {0};

    if (argc < 2 || argc > 3) {
        fprintf(stderr, "Usage: %s stories15M.bin [token_id]\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (argc == 3) {
        char *end;
        unsigned long parsed;
        errno = 0;
        parsed = strtoul(argv[2], &end, 10);
        if (errno || *end || parsed > UINT32_MAX)
            die("Invalid token_id");
        token = (unsigned)parsed;
    }
    if (geteuid() != 0)
        die("Run as root");
    if (bits(1.0f) != UINT32_C(0x3F800000))
        die("Expected little-endian IEEE FP32");

    action.sa_handler = on_signal;
    sigemptyset(&action.sa_mask);
    sigaction(SIGINT, &action, NULL);
    sigaction(SIGTERM, &action, NULL);

    check_cmdline();
    model_fd = open(argv[1], O_RDONLY | O_CLOEXEC);
    if (model_fd < 0 || fstat(model_fd, &st) != 0 || st.st_size < 28)
        die("Cannot open a valid FP32 checkpoint");
    file_size = (uint64_t)st.st_size;
    pread_exact(model_fd, &c, sizeof(c), 0);

    if (c.dim < 4 || c.dim > 8192 || (c.dim & 3) ||
        c.n_layers <= 0 || c.n_layers > 1024 ||
        c.n_heads <= 0 || c.dim % c.n_heads ||
        c.n_kv_heads <= 0 || c.n_kv_heads > c.n_heads ||
        c.vocab_size == INT32_MIN || c.vocab_size == 0 ||
        c.hidden_dim <= 0 || c.seq_len <= 0)
        die("Unsupported or invalid run.c FP32 Config");

    vocab = c.vocab_size < 0 ?
            (uint64_t)(-(int64_t)c.vocab_size) :
            (uint64_t)c.vocab_size;
    if (vocab > 1000000 || token >= vocab)
        die("Invalid vocabulary size or token ID");

    dim = (size_t)c.dim;
    count = dim * dim;
    embed_offset = sizeof(c) + (uint64_t)token * dim * 4;
    rms_offset = sizeof(c) + vocab * dim * 4;
    wq_offset = rms_offset + (uint64_t)c.n_layers * dim * 4;

    check_file_range(embed_offset, dim * 4, file_size);
    check_file_range(rms_offset, dim * 4, file_size);
    check_file_range(wq_offset, (uint64_t)count * 4, file_size);

    embedding = malloc(dim * 4);
    norm_weight = malloc(dim * 4);
    x = malloc(dim * 4);
    w = malloc(count * 4);
    reference = malloc(dim * 4);
    if (!embedding || !norm_weight || !x || !w || !reference)
        die("Cannot allocate CPU buffers");

    pread_exact(model_fd, embedding, dim * 4, embed_offset);
    pread_exact(model_fd, norm_weight, dim * 4, rms_offset);
    pread_exact(model_fd, w, count * 4, wq_offset);
    close(model_fd);

    /* Identical operation order to run.c attention RMSNorm. */
    float ss = 0.0f;
    for (size_t j = 0; j < dim; ++j)
        ss += embedding[j] * embedding[j];
    ss /= (float)dim;
    ss += 1e-5f;
    ss = 1.0f / sqrtf(ss);
    for (size_t j = 0; j < dim; ++j)
        x[j] = norm_weight[j] * (ss * embedding[j]);

    /* Match the RTL's separate FP32 multiply and add, left to right. */
    for (size_t i = 0; i < dim; ++i) {
        volatile float acc = 0.0f;
        for (size_t j = 0; j < dim; ++j) {
            volatile float product = w[i * dim + j] * x[j];
            acc = acc + product;
        }
        reference[i] = acc;
    }

    printf("Model: %s; token=%u; dim=%d; layers=%d; vocab=%" PRIu64 "\n",
           argv[1], token, c.dim, c.n_layers, vocab);
    printf("First-layer wq file offset=0x%" PRIx64
           ", W bytes=%zu; comparing before RoPE\n",
           wq_offset, count * 4);

    lock_fd = open("/run/de25_shared_ddr.lock",
                   O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (lock_fd < 0 || flock(lock_fd, LOCK_EX | LOCK_NB) != 0)
        die("Cannot acquire cooperative shared-DDR lock");

    mem_fd = open("/dev/mem", O_RDWR | O_SYNC | O_CLOEXEC);
    if (mem_fd < 0)
        die("Cannot open /dev/mem");

    csr = map_phys(mem_fd, CSR_BASE, 4096);
    fixed = map_phys(mem_fd, FIXED_BASE, 4096);
    ddr = map_phys(mem_fd, DDR_BASE, 4096);
    fp32 = map_phys(mem_fd, FP32_BASE, 4096);

    if (read_reg(csr, VERSION) != UINT32_C(0x47564D31) ||
        read_reg(fixed, VERSION) != UINT32_C(0x474D5631) ||
        read_reg(fp32, 0x18) != UINT32_C(0x46500001))
        die("Unexpected component VERSION/address");
    if (dim > read_reg(csr, MAX_ROWS) ||
        dim > read_reg(csr, MAX_COLS))
        die("Model dimension exceeds hardware limit");
    require_idle(csr, fixed, ddr, fp32);

    wr = map_region(mem_fd, W_PHYS, count);
    xr = map_region(mem_fd, X_PHYS, dim);
    yr = map_region(mem_fd, Y_PHYS, dim);
    check_separate(wr, xr);
    check_separate(wr, yr);
    check_separate(xr, yr);

    set_guards(wr, 0);
    set_guards(xr, 1);
    set_guards(yr, 2);
    for (size_t i = 0; i < count; ++i)
        wr.data[i] = bits(w[i]);
    for (size_t i = 0; i < dim; ++i) {
        xr.data[i] = bits(x[i]);
        yr.data[i] = POISON;
    }
    barrier();

    for (size_t i = 0; i < count; ++i)
        if (wr.data[i] != bits(w[i]))
            die("DDR W readback mismatch");
    for (size_t i = 0; i < dim; ++i)
        if (xr.data[i] != bits(x[i]) || yr.data[i] != POISON)
            die("DDR x readback or y poison mismatch");

    set_address(csr, W_LO, W_PHYS);
    set_address(csr, X_LO, X_PHYS);
    set_address(csr, Y_LO, Y_PHYS);
    write_reg(csr, ROWS, (uint32_t)dim);
    write_reg(csr, COLS, (uint32_t)dim);
    if (read_reg(csr, ROWS) != dim ||
        read_reg(csr, COLS) != dim)
        die("Shape CSR readback mismatch");

    write_reg(csr, CTRL, 4); /* CLEAR only while idle. */
    if (read_reg(csr, STATUS) != 0)
        die("CLEAR did not reset STATUS");

    if (interrupted)
        die("Interrupted before START");
    start = now_ms();
    in_flight = 1;
    write_reg(csr, CTRL, 1);

    for (;;) {
        struct timespec pause_time = { .tv_sec = 0, .tv_nsec = 100000 };
        if (interrupted)
            die("Interrupted while FPGA completion was unconfirmed");

        status = read_reg(csr, STATUS);
        if (!(status & 1) && (status & 2)) {
            in_flight = 0;
            break;
        }
        if (now_ms() - start >= TIMEOUT_MS) {
            fprintf(stderr, "STATUS=0x%08" PRIx32
                    " DEBUG=0x%08" PRIx32
                    " ROW=%" PRIu32 " COL=%" PRIu32 "\n",
                    status, read_reg(csr, DEBUG),
                    read_reg(csr, ROW_INDEX),
                    read_reg(csr, COL_INDEX));
            die("GEMV timeout; no automatic CLEAR or retry");
        }
        nanosleep(&pause_time, NULL);
    }

    printf("STATUS=0x%08" PRIx32 " CYCLES=%" PRIu32
           " host_wait=%" PRIu64 " ms\n",
           status, read_reg(csr, CYCLES), now_ms() - start);
    if (status != 2)
        die("GEMV reported an error");
    if (read_reg(csr, ROW_INDEX) != dim - 1 ||
        read_reg(csr, COL_INDEX) != dim - 1)
        die("Final row/column index mismatch");

    barrier();
    check_guards(wr, 0);
    check_guards(xr, 1);
    check_guards(yr, 2);
    for (size_t i = 0; i < count; ++i)
        if (wr.data[i] != bits(w[i]))
            die("W changed during GEMV");
    for (size_t i = 0; i < dim; ++i)
        if (xr.data[i] != bits(x[i]))
            die("x changed during GEMV");

    for (size_t i = 0; i < dim; ++i) {
        uint32_t got_bits = yr.data[i];
        uint32_t ref_bits = bits(reference[i]);
        float got = value(got_bits);
        double abs_error, rel_error, limit;
        uint32_t a, b, ulp;

        if (!isfinite(got) || !isfinite(reference[i])) {
            if (bad < 8)
                fprintf(stderr, "Q[%zu] non-finite: FPGA=0x%08" PRIx32
                        " CPU=0x%08" PRIx32 "\n",
                        i, got_bits, ref_bits);
            ++bad;
            continue;
        }

        if (got_bits == ref_bits)
            ++exact;
        else if (dim && (dim <= 16 || (i < 8)))
            printf("Q[%zu] FPGA=0x%08" PRIx32 " (%g)"
                   " CPU=0x%08" PRIx32 " (%g)\n",
                   i, got_bits, (double)got,
                   ref_bits, (double)reference[i]);

        abs_error = fabs((double)got - reference[i]);
        rel_error = abs_error /
                    fmax(fabs((double)reference[i]), 1e-12);
        limit = 1e-5 + 1e-4 * fabs((double)reference[i]);
        a = ordered_bits(got_bits);
        b = ordered_bits(ref_bits);
        ulp = a > b ? a - b : b - a;

        if (abs_error > max_abs) max_abs = abs_error;
        if (rel_error > max_rel) max_rel = rel_error;
        if (ulp > max_ulp) max_ulp = ulp;
        if (abs_error > limit) {
            if (bad < 8)
                fprintf(stderr,
                        "Q[%zu] exceeds tolerance: FPGA=%g CPU=%g "
                        "abs=%.9g ULP=%" PRIu32 "\n",
                        i, (double)got, (double)reference[i],
                        abs_error, ulp);
            ++bad;
        }
    }

    printf("Exact=%" PRIu32 "/%zu; max_abs=%.9g; "
           "max_rel=%.9g; max_ULP=%" PRIu32
           "; out_of_tolerance=%" PRIu32 "\n",
           exact, dim, max_abs, max_rel, max_ulp, bad);
    if (bad)
        die("Real-model Q projection differs beyond tolerance");

    puts("[PASS] First-layer real-model FP32 Q projection");
    return EXIT_SUCCESS;
}