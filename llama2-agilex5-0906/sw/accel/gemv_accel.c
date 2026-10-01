#define _GNU_SOURCE

#ifndef _FILE_OFFSET_BITS
#define _FILE_OFFSET_BITS 64
#endif

#include "gemv_accel.h"

#include <errno.h>
#include <fcntl.h>
#include <float.h>
#include <inttypes.h>
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#if !defined(__aarch64__)
#error "gemv_accel requires AArch64 Linux"
#endif

#if defined(__FAST_MATH__)
#error "Do not build with -ffast-math or -Ofast"
#endif

_Static_assert(sizeof(float) == 4, "FP32 is required");
_Static_assert(FLT_RADIX == 2 && FLT_MANT_DIG == 24 &&
               FLT_MAX_EXP == 128, "IEEE binary32 is required");
_Static_assert(sizeof(off_t) >= 8, "64-bit off_t is required");

#define VAR_CSR   UINT64_C(0x20023000)
#define FIXED_CSR UINT64_C(0x20020000)
#define DDR_CSR   UINT64_C(0x20021000)
#define FP32_CSR  UINT64_C(0x20022000)

#define DDR_BEGIN UINT64_C(0xB8000000)
#define DDR_END   UINT64_C(0xC0000000)

#define W_PHYS UINT64_C(0xB8000040)
#define X_PHYS UINT64_C(0xBFF00000)
#define Y_PHYS UINT64_C(0xBFF10000)

#define GUARD_WORDS 16u
#define GUARD_BYTES 64u

#define Y_POISON UINT32_C(0x7FC00000)
#define TIMEOUT_NS UINT64_C(60000000000)
#define LOCK_PATH "/run/de25_shared_ddr.lock"
#define RESIDENT_MAP_SLOT 7

enum {
    R_CTRL = 0x00,
    R_STATUS = 0x04,
    R_W_LO = 0x08,
    R_X_LO = 0x10,
    R_Y_LO = 0x18,
    R_CYCLES = 0x20,
    R_VERSION = 0x24,
    R_DEBUG = 0x28,
    R_ROWS = 0x2C,
    R_COLS = 0x30,
    R_MAX_ROWS = 0x34,
    R_MAX_COLS = 0x38,
    R_ROW_INDEX = 0x3C,
    R_COL_INDEX = 0x40
};

typedef struct {
    void *base;
    size_t length;
    volatile uint32_t *p;
} Mapping;

typedef struct {
    const float *source;
    volatile uint32_t *guard_base;
    uint64_t phys;
} ResidentWeight;

typedef struct {
    int mem_fd;
    int lock_fd;

    /*
     * variable CSR, fixed CSR, DDR CSR, FP32 CSR,
     * staging W, x, y, resident weight pool
     */
    Mapping maps[8];

    uint32_t dim;
    size_t w_words;

    /*
     * Set by gemv_accel_open().
     * 1: verify W/x before and after execution.
     * 0: skip those two full readback comparisons.
     */
    int full_input_readback;

    int resident_weights;
    int weights_prepared;

    ResidentWeight *weights;
    size_t weight_count;

    int ready;
    int failed;
    int in_flight;
    int timing_valid;

    GemvAccelTiming last;


} Accel;

static Accel g = {
    .mem_fd = -1,
    .lock_fd = -1
};

static void barrier(void)
{
    __asm__ volatile("dsb sy" ::: "memory");
}

static uint32_t fp_bits(float f)
{
    uint32_t u;
    memcpy(&u, &f, sizeof(u));
    return u;
}

uint64_t gemv_accel_now_ns(void)
{
    struct timespec t;

    if (clock_gettime(CLOCK_MONOTONIC, &t) != 0) {
        fprintf(stderr, "clock_gettime failed: %s\n", strerror(errno));

        if (g.in_flight)
            fprintf(stderr,
                    "FPGA completion is unconfirmed; "
                    "no transaction cancellation was performed.\n");

        exit(EXIT_FAILURE);
    }

    return (uint64_t)t.tv_sec * UINT64_C(1000000000) +
           (uint64_t)t.tv_nsec;
}

/* End one nonoverlapping timing interval and begin the next. */
static void mark_time(uint64_t *previous, uint64_t *field)
{
    uint64_t now = gemv_accel_now_ns();
    *field = now - *previous;
    *previous = now;
}

static uint32_t reg_read(unsigned slot, unsigned offset)
{
    uint32_t u;

    barrier();
    u = g.maps[slot].p[offset / 4];
    barrier();

    return u;
}

static void reg_write(unsigned offset, uint32_t value)
{
    barrier();
    g.maps[0].p[offset / 4] = value;
    barrier();
}

static int check_cmdline(void)
{
    FILE *f;
    char *line = NULL;
    size_t capacity = 0;
    ssize_t length;
    int count = 0;
    int valid = 1;
    char *save = NULL;

    f = fopen("/proc/cmdline", "r");
    if (!f)
        return -1;

    length = getline(&line, &capacity, f);
    fclose(f);

    if (length < 0) {
        free(line);
        return -1;
    }

    for (char *p = strtok_r(line, " \t\r\n", &save);
         p;
         p = strtok_r(NULL, " \t\r\n", &save)) {

        if (strncmp(p, "mem=", 4) == 0) {
            ++count;

            if (strcmp(p, "mem=896M") != 0)
                valid = 0;
        }
    }

    free(line);
    return valid && count == 1 ? 0 : -1;
}

static int map_physical(unsigned slot, uint64_t phys, size_t bytes)
{
    long page_size = sysconf(_SC_PAGESIZE);
    uint64_t aligned;
    size_t delta, length;
    void *base;

    if (page_size <= 0 ||
        (page_size & (page_size - 1)) != 0)
        return -1;

    if (bytes == 0 ||
        phys > (uint64_t)INT64_MAX ||
        (uint64_t)bytes > (uint64_t)INT64_MAX - phys)
        return -1;

    aligned = phys & ~((uint64_t)page_size - 1);
    delta = (size_t)(phys - aligned);

    if (delta > SIZE_MAX - (size_t)page_size ||
        bytes > SIZE_MAX - delta - (size_t)page_size)
        return -1;

    length = (bytes + delta + (size_t)page_size - 1) &
             ~((size_t)page_size - 1);

    base = mmap(NULL, length,
                PROT_READ | PROT_WRITE,
                MAP_SHARED, g.mem_fd, (off_t)aligned);

    if (base == MAP_FAILED)
        return -1;

    g.maps[slot].base = base;
    g.maps[slot].length = length;
    g.maps[slot].p =
        (volatile uint32_t *)((unsigned char *)base + delta);

    return 0;
}

static volatile uint32_t *data(unsigned slot)
{
    return g.maps[slot].p + GUARD_WORDS;
}

static uint32_t guard_value(unsigned slot, unsigned index, int after)
{
    return UINT32_C(0x13579BDF) ^
           ((uint32_t)slot << 24) ^
           ((uint32_t)index * UINT32_C(0x9E3779B9)) ^
           (after ? UINT32_C(0xFFFF0000) : 0);
}

static void set_guards_at(
    volatile uint32_t *p,
    unsigned slot,
    size_t words)
{
    for (unsigned i = 0; i < GUARD_WORDS; ++i) {
        p[i] = guard_value(slot, i, 0);
        p[GUARD_WORDS + words + i] =
            guard_value(slot, i, 1);
    }
}

static int guards_ok_at(
    volatile uint32_t *p,
    unsigned slot,
    size_t words)
{
    for (unsigned i = 0; i < GUARD_WORDS; ++i) {
        if (p[i] != guard_value(slot, i, 0) ||
            p[GUARD_WORDS + words + i] !=
                guard_value(slot, i, 1))
            return 0;
    }

    return 1;
}

static void set_guards(unsigned slot, size_t words)
{
    set_guards_at(g.maps[slot].p, slot, words);
}

static int guards_ok(unsigned slot, size_t words)
{
    return guards_ok_at(g.maps[slot].p, slot, words);
}

static int all_idle(void)
{
    for (unsigned slot = 0; slot < 4; ++slot) {
        if (reg_read(slot, R_STATUS) & 1u)
            return 0;
    }

    return 1;
}

static int write_checked(unsigned offset, uint32_t value)
{
    reg_write(offset, value);
    return reg_read(0, offset) == value ? 0 : -1;
}

static int address_checked(unsigned offset, uint64_t addr)
{
    if (write_checked(offset, (uint32_t)addr) != 0)
        return -1;

    return write_checked(offset + 4, (uint32_t)(addr >> 32));
}

static void print_status(void)
{
    fprintf(stderr,
            "GEMV STATUS=0x%08" PRIx32
            " DEBUG=0x%08" PRIx32
            " CYCLES=%" PRIu32
            " ROW=%" PRIu32
            " COL=%" PRIu32 "\n",
            reg_read(0, R_STATUS),
            reg_read(0, R_DEBUG),
            reg_read(0, R_CYCLES),
            reg_read(0, R_ROW_INDEX),
            reg_read(0, R_COL_INDEX));
}

static int run_error(const char *message)
{
    g.failed = 1;
    g.timing_valid = 0;

    fprintf(stderr, "GEMV error: %s\n", message);

    if (g.in_flight)
        fprintf(stderr,
                "FPGA completion is unconfirmed. "
                "Do not reuse DDR, CLEAR, or retry START.\n");

    return -1;
}

void gemv_accel_close(void)
{
    if (g.in_flight)
        fprintf(stderr,
                "Closing the process does not cancel "
                "an unfinished FPGA AXI transaction.\n");

    for (unsigned i = 0; i < 8; ++i) {
        if (g.maps[i].length != 0)
            munmap(g.maps[i].base, g.maps[i].length);
    }

    if (g.mem_fd >= 0)
        close(g.mem_fd);

    if (g.lock_fd >= 0)
        close(g.lock_fd);

    /* The lock file is deliberately not unlinked. */
    free(g.weights);

    g = (Accel) {
        .mem_fd = -1,
        .lock_fd = -1
    };
}

int gemv_accel_open(uint32_t dim)
{
    uint64_t w_bytes;
    uint64_t vector_bytes;
    const char *mode_text;
    const char *weights_text = getenv("GEMV_WEIGHTS");

    if (weights_text == NULL)
        weights_text = "copy";

    if (strcmp(weights_text, "copy") == 0) {
        g.resident_weights = 0;
    } else if (strcmp(weights_text, "resident") == 0) {
        g.resident_weights = 1;
    } else {
        fprintf(stderr,
                "Invalid GEMV_WEIGHTS='%s'; "
                "expected copy or resident.\n",
                weights_text);
        return -1;
    }

    if (g.ready || g.mem_fd >= 0 || g.lock_fd >= 0)
        return -1;
    /*
     * Select once, before mapping or accessing hardware.
     * Unset means verify. Empty/unknown values are errors.
     */
    mode_text = getenv("GEMV_MODE");
    if (mode_text == NULL)
        mode_text = "verify";
    if (strcmp(mode_text, "verify") == 0) {
        g.full_input_readback = 1;
    } else if (strcmp(mode_text, "perf") == 0) {
        g.full_input_readback = 0;
    } else {
        fprintf(stderr,
                "Invalid GEMV_MODE='%s'; expected verify or perf.\n",
                mode_text);
        return -1;
    }
    if (geteuid() != 0) {
        fprintf(stderr, "Run the FPGA program with sudo.\n");
        return -1;
    }

    if (check_cmdline() != 0) {
        fprintf(stderr,
                "GEMV requires exactly one mem=896M boot argument.\n");
        return -1;
    }

    if (dim < 4 || dim > 8192 || (dim & 3u)) {
        fprintf(stderr, "Unsupported dim=%" PRIu32 "\n", dim);
        return -1;
    }

    w_bytes = (uint64_t)dim * dim * sizeof(float);
    vector_bytes = (uint64_t)dim * sizeof(float);

    if (W_PHYS < DDR_BEGIN + GUARD_BYTES ||
        W_PHYS + w_bytes + GUARD_BYTES > X_PHYS - GUARD_BYTES ||
        X_PHYS + vector_bytes + GUARD_BYTES > Y_PHYS - GUARD_BYTES ||
        Y_PHYS + vector_bytes + GUARD_BYTES > DDR_END) {
        fprintf(stderr,
                "Guarded buffers do not fit the shared DDR layout.\n");
        return -1;
    }

    g.lock_fd = open(LOCK_PATH,
                     O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW,
                     0600);

    if (g.lock_fd < 0) {
        fprintf(stderr, "open %s: %s\n", LOCK_PATH, strerror(errno));
        goto error;
    }

    if (flock(g.lock_fd, LOCK_EX | LOCK_NB) != 0) {
        fprintf(stderr, "flock %s: %s\n", LOCK_PATH, strerror(errno));
        goto error;
    }

    g.mem_fd = open("/dev/mem", O_RDWR | O_SYNC | O_CLOEXEC);

    if (g.mem_fd < 0) {
        perror("open /dev/mem");
        goto error;
    }

    if (map_physical(0, VAR_CSR, 4096) ||
        map_physical(1, FIXED_CSR, 4096) ||
        map_physical(2, DDR_CSR, 4096) ||
        map_physical(3, FP32_CSR, 4096)) {
        fprintf(stderr, "Cannot map CSR registers.\n");
        goto error;
    }

    if (reg_read(0, R_VERSION) != UINT32_C(0x47564D31) ||
        reg_read(1, R_VERSION) != UINT32_C(0x474D5631) ||
        reg_read(3, 0x18) != UINT32_C(0x46500001)) {
        fprintf(stderr, "Component VERSION/address mismatch.\n");
        goto error;
    }

    if (dim > reg_read(0, R_MAX_ROWS) ||
        dim > reg_read(0, R_MAX_COLS) ||
        !all_idle()) {
        fprintf(stderr, "Unsupported hardware limits or BUSY state.\n");
        goto error;
    }

    if (map_physical(4, W_PHYS - GUARD_BYTES,
                     (size_t)w_bytes + 2 * GUARD_BYTES) ||
        map_physical(5, X_PHYS - GUARD_BYTES,
                     (size_t)vector_bytes + 2 * GUARD_BYTES) ||
        map_physical(6, Y_PHYS - GUARD_BYTES,
                     (size_t)vector_bytes + 2 * GUARD_BYTES)) {
        fprintf(stderr, "Cannot map shared DDR buffers.\n");
        goto error;
    }

    g.dim = dim;
    g.w_words = (size_t)dim * dim;
    g.ready = 1;

    fprintf(stderr,
            "GEMV mode: input_readback=%s weights=%s\n",
            g.full_input_readback ? "verify" : "perf",
            g.resident_weights ? "resident" : "copy");

    fprintf(stderr,
            "GEMV ready: CSR=0x%08" PRIx64
            ", dim=%" PRIu32
            ", mode=%s, full_input_readback=%s\n",
            VAR_CSR, dim,
            g.full_input_readback ? "verify" : "perf",
            g.full_input_readback ? "on" : "off");
    fprintf(stderr,
            "GEMV checks: guards=on, output_poison=on, "
            "CSR_readback=on, completion=on; W_copy=%s\n",
            g.resident_weights ? "initial_load_only" : "every_call");

    return 0;

error:
    gemv_accel_close();
    return -1;
}

\
int gemv_accel_prepare_weights(
    const float *const *weights,
    size_t count)
{
    uint64_t begin = gemv_accel_now_ns();

    if (!g.ready || g.failed || g.in_flight ||
        g.weights_prepared || !weights || count == 0)
        return run_error("Invalid weight preparation request");

    for (size_t i = 0; i < count; ++i) {
        if (!weights[i])
            return run_error("NULL weight source");

        for (size_t j = 0; j < i; ++j) {
            if (weights[i] == weights[j])
                return run_error("Duplicate weight source");
        }
    }

    if (!g.resident_weights) {
        g.weights_prepared = 1;

        fprintf(stderr,
                "[WEIGHTS] mode=copy matrices=%zu "
                "W_copy=every_call\n",
                count);
        return 0;
    }

    if (!all_idle())
        return run_error(
            "A board component is BUSY during weight loading");

    uint64_t w_bytes =
        (uint64_t)g.w_words * sizeof(uint32_t);

    uint64_t stride =
        w_bytes + 2 * (uint64_t)GUARD_BYTES;

    uint64_t pool_begin =
        W_PHYS + w_bytes + GUARD_BYTES;

    uint64_t pool_limit =
        X_PHYS - GUARD_BYTES;

    if (pool_begin >= pool_limit ||
        count > (pool_limit - pool_begin) / stride)
        return run_error(
            "Resident weights do not fit before x buffer");

    if (count > SIZE_MAX / sizeof(*g.weights) ||
        stride > SIZE_MAX / count)
        return run_error(
            "Resident weight allocation overflow");

    uint64_t pool_bytes64 = stride * (uint64_t)count;

    if (pool_bytes64 > SIZE_MAX)
        return run_error("Resident weight map is too large");

    size_t pool_bytes = (size_t)pool_bytes64;
    size_t stride_words = (size_t)(stride / sizeof(uint32_t));

    g.weights = calloc(count, sizeof(*g.weights));
    if (!g.weights)
        return run_error(
            "Cannot allocate resident weight table");

    if (map_physical(
            RESIDENT_MAP_SLOT,
            pool_begin,
            pool_bytes) != 0)
        return run_error(
            "Cannot map resident weight pool");

    for (size_t i = 0; i < count; ++i) {
        ResidentWeight *entry = &g.weights[i];

        entry->source = weights[i];
        entry->guard_base =
            g.maps[RESIDENT_MAP_SLOT].p +
            i * stride_words;

        entry->phys =
            pool_begin +
            (uint64_t)i * stride +
            GUARD_BYTES;

        volatile uint32_t *dw =
            entry->guard_base + GUARD_WORDS;

        set_guards_at(
            entry->guard_base,
            RESIDENT_MAP_SLOT,
            g.w_words);

        for (size_t j = 0; j < g.w_words; ++j)
            dw[j] = fp_bits(entry->source[j]);

        barrier();

        /*
         * Initial upload verification is always enabled.
         * It is outside the forward timing interval.
         */
        for (size_t j = 0; j < g.w_words; ++j) {
            if (dw[j] != fp_bits(entry->source[j])) {
                fprintf(stderr,
                        "[WEIGHTS] matrix=%zu word=%zu\n",
                        i, j);
                return run_error(
                    "Resident weight upload/readback mismatch");
            }
        }

        if (!guards_ok_at(
                entry->guard_base,
                RESIDENT_MAP_SLOT,
                g.w_words))
            return run_error(
                "Resident weight guard mismatch");

        barrier();
    }

    g.weight_count = count;
    g.weights_prepared = 1;

    uint64_t elapsed =
        gemv_accel_now_ns() - begin;

    fprintf(stderr,
            "[WEIGHTS] mode=resident matrices=%zu "
            "payload_bytes=%" PRIu64
            " pool_bytes=%zu load_ms=%.3f "
            "initial_readback=PASS\n",
            count,
            (uint64_t)count * w_bytes,
            pool_bytes,
            (double)elapsed / 1000000.0);

    return 0;
}

int gemv_accel_get_last_timing(GemvAccelTiming *out)
{
    if (!out || !g.timing_valid)
        return -1;

    *out = g.last;
    return 0;
}

int gemv_accel_run(
    float *y,
    const float *x,
    const float *w,
    uint32_t rows,
    uint32_t cols)
{
    uint64_t begin = gemv_accel_now_ns();
    uint64_t checkpoint = begin;
    uint64_t wait_begin;

    volatile uint32_t *dw;
    volatile uint32_t *dx;
    volatile uint32_t *dy;
    volatile uint32_t *w_guard;

    uint64_t w_phys = W_PHYS;

    uint32_t status;

    g.timing_valid = 0;
    memset(&g.last, 0, sizeof(g.last));

    if (!g.ready || g.failed || g.in_flight ||
        !y || !x || !w ||
        rows != g.dim || cols != g.dim)
        return run_error("Invalid call or accelerator unavailable");

    if (!all_idle())
        return run_error("A board component is BUSY");

    if (g.resident_weights) {
        const ResidentWeight *entry = NULL;

        if (!g.weights_prepared || !g.weights)
            return run_error(
                "Resident weights were not prepared");

        for (size_t i = 0; i < g.weight_count; ++i) {
            if (g.weights[i].source == w) {
                entry = &g.weights[i];
                break;
            }
        }

        if (!entry)
            return run_error(
                "Unregistered resident weight pointer");

        w_guard = entry->guard_base;
        w_phys = entry->phys;
    } else {
        w_guard = g.maps[4].p;
    }

    dw = w_guard + GUARD_WORDS;
    dx = data(5);
    dy = data(6);

    mark_time(&checkpoint, &g.last.preflight_ns);

    /*
     * Resident W guards are initialized once during loading.
     * Do not rewrite them for every call.
     */
    if (!g.resident_weights)
        set_guards(4, g.w_words);

    set_guards(5, cols);
    set_guards(6, rows);

    for (uint32_t i = 0; i < rows; ++i)
        dy[i] = Y_POISON;

    barrier();
    mark_time(&checkpoint, &g.last.prepare_ns);

    /* W -> shared DDR, only in copy mode. */
    if (!g.resident_weights) {
        for (size_t i = 0; i < g.w_words; ++i)
            dw[i] = fp_bits(w[i]);
    }

    barrier();
    mark_time(&checkpoint, &g.last.w_copy_ns);

    /* x -> shared DDR. */
    for (uint32_t i = 0; i < cols; ++i)
        dx[i] = fp_bits(x[i]);

    barrier();
    mark_time(&checkpoint, &g.last.x_copy_ns);

    /*
     * Optional full input readback.
     * Output poison and guard checks remain enabled in both modes.
     */
    if (g.full_input_readback) {
        for (size_t i = 0; i < g.w_words; ++i) {
            if (dw[i] != fp_bits(w[i]))
                return run_error("W write/readback mismatch");
        }

        for (uint32_t i = 0; i < cols; ++i) {
            if (dx[i] != fp_bits(x[i]))
                return run_error("x write/readback mismatch");
        }
    }

    for (uint32_t i = 0; i < rows; ++i) {
        if (dy[i] != Y_POISON)
            return run_error("Output poison readback mismatch");
    }

    if (!guards_ok_at(w_guard,
                      g.resident_weights ? RESIDENT_MAP_SLOT : 4u,
                      g.w_words) ||
        !guards_ok(5, cols) ||
        !guards_ok(6, rows))
        return run_error("Guard mismatch before START");

    barrier();
    mark_time(&checkpoint, &g.last.precheck_ns);

    /* Configure CSR and clear old completion. */
    if (address_checked(R_W_LO, w_phys) ||
        address_checked(R_X_LO, X_PHYS) ||
        address_checked(R_Y_LO, Y_PHYS) ||
        write_checked(R_ROWS, rows) ||
        write_checked(R_COLS, cols))
        return run_error("CSR configuration readback mismatch");

    reg_write(R_CTRL, 4);

    if (reg_read(0, R_STATUS) != 0 ||
        reg_read(0, R_CYCLES) != 0 ||
        !all_idle())
        return run_error("CLEAR or pre-START idle check failed");

    mark_time(&checkpoint, &g.last.config_ns);

    /*
     * Software observation interval:
     * START write -> first observation of BUSY=0 and DONE=1.
     */
    wait_begin = checkpoint;
    g.in_flight = 1;
    reg_write(R_CTRL, 1);

    for (;;) {
        struct timespec pause_time = {
            .tv_sec = 0,
            .tv_nsec = 100000
        };

        status = reg_read(0, R_STATUS);

        if (!(status & 1u) && (status & 2u)) {
            g.in_flight = 0;
            break;
        }

        if (gemv_accel_now_ns() - wait_begin >= TIMEOUT_NS) {
            print_status();
            return run_error("Timeout; no CLEAR or automatic retry");
        }

        if (nanosleep(&pause_time, NULL) != 0 && errno != EINTR)
            return run_error("nanosleep failed");
    }

    mark_time(&checkpoint, &g.last.wait_ns);

    /* Completion diagnostics are separate from polling time. */
    g.last.cycles = reg_read(0, R_CYCLES);

    if (status != 2u ||
        reg_read(0, R_ROW_INDEX) != rows - 1 ||
        reg_read(0, R_COL_INDEX) != cols - 1 ||
        g.last.cycles == 0 ||
        g.last.cycles == UINT32_MAX) {
        print_status();
        return run_error("Unexpected completion status, index or cycles");
    }

    mark_time(&checkpoint, &g.last.completion_ns);

    /*
     * Guard checks remain enabled in both modes.
     * Full input integrity readback is optional.
     */
    barrier();

    if (!guards_ok_at(w_guard,
                      g.resident_weights ? RESIDENT_MAP_SLOT : 4u,
                      g.w_words) ||
        !guards_ok(5, cols) ||
        !guards_ok(6, rows))
        return run_error("Guard mismatch after completion");

    if (g.full_input_readback) {
        for (size_t i = 0; i < g.w_words; ++i) {
            if (dw[i] != fp_bits(w[i]))
                return run_error("W changed during GEMV");
        }

        for (uint32_t i = 0; i < cols; ++i) {
            if (dx[i] != fp_bits(x[i]))
                return run_error("x changed during GEMV");
        }
    }

    barrier();
    mark_time(&checkpoint, &g.last.postcheck_ns);

    /* Shared DDR y -> ordinary CPU memory. */
    for (uint32_t i = 0; i < rows; ++i) {
        uint32_t u = dy[i];

        if (u == Y_POISON)
            return run_error("Output remains unwritten");

        memcpy(&y[i], &u, sizeof(u));
    }

    barrier();
    mark_time(&checkpoint, &g.last.y_copy_ns);

    g.last.total_ns = gemv_accel_now_ns() - begin;
    g.timing_valid = 1;

    return 0;
}