#define _GNU_SOURCE

#ifndef _FILE_OFFSET_BITS
#define _FILE_OFFSET_BITS 64
#endif

#include <errno.h>
#include <fenv.h>
#include <fcntl.h>
#include <float.h>
#include <inttypes.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#if !defined(__aarch64__)
#error "Build this program for AArch64 Linux."
#endif

#if defined(__FAST_MATH__)
#error "Do not compile this test with -ffast-math or -Ofast."
#endif

_Static_assert(sizeof(float) == 4, "32-bit float is required.");
_Static_assert(FLT_RADIX == 2 && FLT_MANT_DIG == 24 &&
               FLT_MAX_EXP == 128,
               "IEEE binary32-compatible float is required.");
_Static_assert(sizeof(off_t) >= 8, "64-bit off_t is required.");

/* ------------------------------------------------------------
 * Current board memory contract.
 * ------------------------------------------------------------ */

#define SHARED_BEGIN UINT64_C(0xB8000000)
#define SHARED_END   UINT64_C(0xC0000000)

/*
 * Leave 64 bytes before W for a guard.
 * X and Y have separate fixed windows.
 */
#define W_PHYS UINT64_C(0xB8000040)
#define X_PHYS UINT64_C(0xBFF00000)
#define Y_PHYS UINT64_C(0xBFF10000)

#define GUARD_WORDS 16u
#define GUARD_BYTES (GUARD_WORDS * sizeof(uint32_t))

/* Existing components retained in this project. */
#define OLD_GEMV_BASE UINT64_C(0x20020000)
#define DDR_BASE      UINT64_C(0x20021000)
#define FP32_BASE     UINT64_C(0x20022000)

#define OLD_GEMV_VERSION UINT32_C(0x474D5631)
#define FP32_VERSION     UINT32_C(0x46500001)
#define VAR_GEMV_VERSION UINT32_C(0x47564D31)

#define LOCK_PATH "/run/de25_shared_ddr.lock"

/* ------------------------------------------------------------
 * gemv_var_fp32 CSR byte offsets.
 * ------------------------------------------------------------ */

enum {
    R_CTRL       = 0x00,
    R_STATUS     = 0x04,
    R_W_LO       = 0x08,
    R_W_HI       = 0x0C,
    R_X_LO       = 0x10,
    R_X_HI       = 0x14,
    R_Y_LO       = 0x18,
    R_Y_HI       = 0x1C,
    R_CYCLES     = 0x20,
    R_VERSION    = 0x24,
    R_DEBUG      = 0x28,
    R_ROWS       = 0x2C,
    R_COLS       = 0x30,
    R_MAX_ROWS   = 0x34,
    R_MAX_COLS   = 0x38,
    R_ROW_INDEX  = 0x3C,
    R_COL_INDEX  = 0x40
};

#define CTRL_START UINT32_C(1)
#define CTRL_CLEAR UINT32_C(4)

#define ST_BUSY       UINT32_C(1)
#define ST_DONE       UINT32_C(2)
#define ST_OK         UINT32_C(0x02)
#define ST_PARAM_DONE UINT32_C(0x0E)

/* ------------------------------------------------------------
 * Data structures and process state.
 * ------------------------------------------------------------ */

struct mapping {
    void *base;
    size_t length;
    volatile uint32_t *p;
};

/*
 * Mapping slots:
 *   0: variable GEMV CSR
 *   1: old fixed GEMV CSR
 *   2: DDR test CSR
 *   3: FP32 test CSR
 *   4: W with guards
 *   5: X with guards
 *   6: Y with guards
 */
static struct mapping maps[7];

struct buffer {
    const char *name;
    uint64_t phys;
    size_t words;
    volatile uint32_t *all;
    volatile uint32_t *data;
};

static struct buffer bufs[3];

struct config {
    uint32_t rows;
    uint32_t cols;
    uint64_t w;
    uint64_t x;
    uint64_t y;
};

struct run_result {
    uint32_t cycles;
    double wall_ms;
};

enum pattern {
    PAT_CLASSIC,
    PAT_IDENTITY,
    PAT_ZERO_W,
    PAT_ZERO_X,
    PAT_CANCEL,
    PAT_RANDOM
};

static int mem_fd = -1;
static int lock_fd = -1;

static float *host_w;
static float *host_x;
static float *host_y;

static uint32_t max_rows;
static uint32_t max_cols;

static uint64_t timeout_ms = 60000;
static unsigned passed;
static unsigned skipped;

static bool in_flight;
static volatile sig_atomic_t interrupted;

/* ------------------------------------------------------------
 * Utilities.
 * ------------------------------------------------------------ */

static inline void memory_barrier(void)
{
    __asm__ volatile("dsb sy" ::: "memory");
}

static uint32_t float_bits(float value)
{
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static float bits_float(uint32_t bits)
{
    float value;
    memcpy(&value, &bits, sizeof(value));
    return value;
}

static bool same_result(uint32_t a, uint32_t b)
{
    if (a == b)
        return true;

    /* Treat +0 and -0 as numerically equal. */
    return ((a & UINT32_C(0x7FFFFFFF)) == 0) &&
           ((b & UINT32_C(0x7FFFFFFF)) == 0);
}

static void unmap_slot(unsigned slot)
{
    if (maps[slot].length != 0) {
        munmap(maps[slot].base, maps[slot].length);
        memset(&maps[slot], 0, sizeof(maps[slot]));
    }
}

static void release_case(void)
{
    for (unsigned i = 4; i < 7; ++i)
        unmap_slot(i);

    free(host_w);
    free(host_x);
    free(host_y);

    host_w = NULL;
    host_x = NULL;
    host_y = NULL;
}

static void cleanup(void)
{
    /*
     * Cleanup only releases process resources.
     * It NEVER writes CLEAR/START and NEVER touches DDR data.
     * munmap/close do not cancel FPGA transactions.
     */
    release_case();

    for (unsigned i = 0; i < 4; ++i)
        unmap_slot(i);

    if (mem_fd >= 0)
        close(mem_fd);

    if (lock_fd >= 0)
        close(lock_fd);

    /* Do not unlink the shared lock file. */
}

static void fail(const char *fmt, ...)
{
    va_list ap;

    fflush(stdout);
    fprintf(stderr, "\n[FAIL] ");

    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);

    fputc('\n', stderr);

    if (in_flight) {
        fprintf(stderr,
            "[WARNING] FPGA completion has NOT been confirmed.\n"
            "Do not reuse shared DDR, retry START, or assume CLEAR "
            "can cancel the transaction.\n");
    }

    exit(EXIT_FAILURE);
}

static void signal_handler(int sig)
{
    (void)sig;
    interrupted = 1;
}

static void check_interrupt(void)
{
    if (interrupted)
        fail("Interrupted by user; no automatic hardware reset or retry.");
}

static uint64_t now_us(void)
{
    struct timespec ts;

    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        fail("clock_gettime: %s", strerror(errno));

    return (uint64_t)ts.tv_sec * UINT64_C(1000000) +
           (uint64_t)ts.tv_nsec / UINT64_C(1000);
}

static uint64_t parse_u64(const char *text)
{
    char *end = NULL;
    unsigned long long value;

    if (!text || !*text || text[0] == '-' || text[0] == '+')
        fail("Invalid unsigned integer: %s", text ? text : "(null)");

    errno = 0;
    value = strtoull(text, &end, 0);

    if (errno != 0 || !end || *end != '\0')
        fail("Invalid unsigned integer: %s", text);

    return (uint64_t)value;
}

static uint32_t parse_u32(const char *text)
{
    uint64_t value = parse_u64(text);

    if (value > UINT32_MAX)
        fail("Value does not fit uint32_t: %s", text);

    return (uint32_t)value;
}

/* ------------------------------------------------------------
 * mmap and MMIO.
 * ------------------------------------------------------------ */

static void map_slot(unsigned slot, uint64_t phys, size_t bytes)
{
    long page_long = sysconf(_SC_PAGESIZE);
    uint64_t page;
    uint64_t aligned;
    size_t delta;
    size_t length;
    void *p;

    if (maps[slot].length != 0)
        fail("Internal error: mapping slot %u already in use.", slot);

    if (page_long <= 0)
        fail("Cannot obtain page size.");

    page = (uint64_t)page_long;

    if ((page & (page - 1)) != 0)
        fail("Unexpected non-power-of-two page size.");

    if (bytes == 0 || phys > (uint64_t)INT64_MAX ||
        (uint64_t)bytes > (uint64_t)INT64_MAX - phys)
        fail("Invalid mmap range.");

    aligned = phys & ~(page - 1);
    delta = (size_t)(phys - aligned);

    if (delta > SIZE_MAX - (size_t)(page - 1) ||
        bytes > SIZE_MAX - delta - (size_t)(page - 1))
        fail("mmap size overflow.");

    length = (bytes + delta + (size_t)page - 1) &
             ~((size_t)page - 1);

    p = mmap(NULL, length, PROT_READ | PROT_WRITE,
             MAP_SHARED, mem_fd, (off_t)aligned);

    if (p == MAP_FAILED)
        fail("mmap physical 0x%016" PRIx64 ": %s",
             phys, strerror(errno));

    maps[slot].base = p;
    maps[slot].length = length;
    maps[slot].p =
        (volatile uint32_t *)((unsigned char *)p + delta);
}

static uint32_t reg_read(unsigned slot, unsigned offset)
{
    uint32_t value;

    memory_barrier();
    value = maps[slot].p[offset / 4];
    memory_barrier();

    return value;
}

static uint32_t rd(unsigned offset)
{
    return reg_read(0, offset);
}

static void wr(unsigned offset, uint32_t value)
{
    check_interrupt();
    memory_barrier();
    maps[0].p[offset / 4] = value;
    memory_barrier();
}

static void write_check(unsigned offset, uint32_t value)
{
    uint32_t got;

    wr(offset, value);
    got = rd(offset);

    if (got != value)
        fail("CSR +0x%02x readback: got 0x%08" PRIx32
             ", expected 0x%08" PRIx32,
             offset, got, value);
}

/* ------------------------------------------------------------
 * Board preflight.
 * ------------------------------------------------------------ */

static void require_reserved_memory(void)
{
    FILE *f;
    char *line = NULL;
    size_t capacity = 0;
    ssize_t length;
    char *save = NULL;
    unsigned mem_args = 0;

    f = fopen("/proc/cmdline", "r");
    if (!f)
        fail("Cannot read /proc/cmdline: %s", strerror(errno));

    length = getline(&line, &capacity, f);
    fclose(f);

    if (length < 0)
        fail("Cannot read Linux command line.");

    for (char *token = strtok_r(line, " \t\r\n", &save);
         token;
         token = strtok_r(NULL, " \t\r\n", &save)) {

        if (strncmp(token, "mem=", 4) == 0) {
            ++mem_args;

            if (strcmp(token, "mem=896M") != 0)
                fail("Unexpected memory argument: %s", token);
        }
    }

    free(line);

    if (mem_args != 1)
        fail("Require exactly one mem=896M argument in /proc/cmdline.");
}

static void require_all_idle(void)
{
    static const char *names[4] = {
        "variable GEMV", "fixed GEMV", "DDR test", "FP32 test"
    };

    check_interrupt();

    for (unsigned i = 0; i < 4; ++i) {
        uint32_t status = reg_read(i, R_STATUS);

        if (status & ST_BUSY)
            fail("%s is BUSY: STATUS=0x%08" PRIx32
                 ". No shared DDR data was intentionally changed "
                 "after this check failed.",
                 names[i], status);
    }
}

static void check_identity(void)
{
    uint32_t version = rd(R_VERSION);

    printf("Variable GEMV VERSION = 0x%08" PRIx32 "\n", version);

    if (version != VAR_GEMV_VERSION)
        fail("Wrong variable GEMV VERSION; verify CSR address and image.");

    if (reg_read(1, 0x24) != OLD_GEMV_VERSION)
        fail("Fixed GEMV identity mismatch at 0x20020000.");

    if (reg_read(3, 0x18) != FP32_VERSION)
        fail("FP32 test identity mismatch at 0x20022000.");

    /*
     * DDR test has no VERSION register.
     * Its base is the project's fixed address contract.
     */
    max_rows = rd(R_MAX_ROWS);
    max_cols = rd(R_MAX_COLS);

    printf("Hardware limits: MAX_ROWS=%" PRIu32
           ", MAX_COLS=%" PRIu32 "\n", max_rows, max_cols);

    if (max_rows < 4 || max_rows > 32768 || (max_rows & 3) ||
        max_cols < 4 || max_cols > 8192 || (max_cols & 3))
        fail("Unexpected hardware limits for this RTL revision.");

    require_all_idle();
}

/* ------------------------------------------------------------
 * Guarded DDR buffers.
 * ------------------------------------------------------------ */

static void setup_buffers(uint32_t rows, uint32_t cols)
{
    uint64_t words[3] = {
        (uint64_t)rows * cols,
        cols,
        rows
    };

    uint64_t phys[3] = { W_PHYS, X_PHYS, Y_PHYS };
    const char *names[3] = { "W", "X", "Y" };

    uint64_t start[3];
    uint64_t end[3];
    size_t total[3];

    for (unsigned i = 0; i < 3; ++i) {
        uint64_t payload;
        uint64_t length;

        if (words[i] > (SIZE_MAX - 2 * GUARD_BYTES) / 4)
            fail("%s size overflow.", names[i]);

        payload = words[i] * 4;
        length = payload + 2 * GUARD_BYTES;

        if (phys[i] < SHARED_BEGIN + GUARD_BYTES)
            fail("%s guard starts below shared DDR.", names[i]);

        start[i] = phys[i] - GUARD_BYTES;

        if (start[i] >= SHARED_END ||
            length > SHARED_END - start[i])
            fail("%s plus guards exceeds shared DDR.", names[i]);

        end[i] = start[i] + length;
        total[i] = (size_t)length;
    }

    for (unsigned i = 0; i < 3; ++i) {
        for (unsigned j = i + 1; j < 3; ++j) {
            if (start[i] < end[j] && start[j] < end[i])
                fail("%s/%s guarded ranges overlap. Matrix too large "
                     "for this test layout.",
                     names[i], names[j]);
        }
    }

    for (unsigned i = 0; i < 3; ++i) {
        map_slot(4 + i, start[i], total[i]);

        bufs[i].name = names[i];
        bufs[i].phys = phys[i];
        bufs[i].words = (size_t)words[i];
        bufs[i].all = maps[4 + i].p;
        bufs[i].data = bufs[i].all + GUARD_WORDS;
    }

    host_w = malloc(bufs[0].words * sizeof(float));
    host_x = malloc(bufs[1].words * sizeof(float));
    host_y = malloc(bufs[2].words * sizeof(float));

    if (!host_w || !host_x || !host_y)
        fail("Host buffer allocation failed.");
}

static uint32_t guard_value(unsigned buffer, unsigned index, bool post)
{
    return UINT32_C(0x13579BDF) ^
           ((uint32_t)buffer << 24) ^
           ((uint32_t)index * UINT32_C(0x9E3779B9)) ^
           (post ? UINT32_C(0xFFFF0000) : UINT32_C(0));
}

static void initialize_guards(void)
{
    for (unsigned b = 0; b < 3; ++b) {
        for (unsigned i = 0; i < GUARD_WORDS; ++i) {
            bufs[b].all[i] = guard_value(b, i, false);

            bufs[b].all[GUARD_WORDS + bufs[b].words + i] =
                guard_value(b, i, true);
        }
    }
}

static void check_guards(void)
{
    memory_barrier();

    for (unsigned b = 0; b < 3; ++b) {
        for (unsigned i = 0; i < GUARD_WORDS; ++i) {
            uint32_t pre = bufs[b].all[i];
            uint32_t post =
                bufs[b].all[GUARD_WORDS + bufs[b].words + i];

            if (pre != guard_value(b, i, false))
                fail("%s leading guard[%u] corrupted.", bufs[b].name, i);

            if (post != guard_value(b, i, true))
                fail("%s trailing guard[%u] corrupted.", bufs[b].name, i);
        }
    }
}

static uint32_t output_poison(size_t index)
{
    /*
     * Always differs from the expected result.
     * Unlike zero-initializing Y, this detects unwritten zero outputs.
     */
    return float_bits(host_y[index]) ^ UINT32_C(0xFFFFFFFF);
}

static void check_inputs(void)
{
    const float *expected[2] = { host_w, host_x };

    memory_barrier();

    for (unsigned b = 0; b < 2; ++b) {
        for (size_t i = 0; i < bufs[b].words; ++i) {
            uint32_t got;
            uint32_t want;

            if ((i & 4095u) == 0)
                check_interrupt();

            got = bufs[b].data[i];
            want = float_bits(expected[b][i]);

            if (got != want)
                fail("%s[%zu] changed/readback failed: "
                     "got 0x%08" PRIx32 ", expected 0x%08" PRIx32,
                     bufs[b].name, i, got, want);
        }
    }
}

static void check_poison(void)
{
    memory_barrier();

    for (size_t i = 0; i < bufs[2].words; ++i) {
        if (bufs[2].data[i] != output_poison(i))
            fail("Y[%zu] poison changed unexpectedly.", i);
    }
}

/* ------------------------------------------------------------
 * Deterministic inputs and serial FP32 reference.
 * ------------------------------------------------------------ */

static uint32_t random_u32(uint32_t *state)
{
    uint32_t x = *state;

    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;

    *state = x;
    return x;
}

static float random_exact_float(uint32_t *state)
{
    int value = (int)(random_u32(state) % 33u) - 16;

    return (float)value * 0.0625f;
}

static void generate_inputs(uint32_t rows, uint32_t cols,
                            enum pattern pattern, uint32_t seed)
{
    uint32_t rng = seed ? seed : UINT32_C(1);

    for (uint32_t j = 0; j < cols; ++j) {
        switch (pattern) {
        case PAT_CLASSIC:
            host_x[j] = (float)(j + 1);
            break;
        case PAT_ZERO_X:
            host_x[j] = 0.0f;
            break;
        case PAT_CANCEL:
            host_x[j] = (j & 1u) ? -1.0f : 1.0f;
            break;
        default:
            host_x[j] = random_exact_float(&rng);
            break;
        }
    }

    for (uint32_t i = 0; i < rows; ++i) {
        check_interrupt();

        for (uint32_t j = 0; j < cols; ++j) {
            size_t k = (size_t)i * cols + j;

            switch (pattern) {
            case PAT_CLASSIC:
                host_w[k] = (float)(k + 1);
                break;
            case PAT_IDENTITY:
                host_w[k] = (i == j) ? 1.0f : 0.0f;
                break;
            case PAT_ZERO_W:
                host_w[k] = 0.0f;
                break;
            case PAT_CANCEL:
                host_w[k] = (float)(1u + (i % 16u)) * 0.125f;
                break;
            default:
                host_w[k] = random_exact_float(&rng);
                break;
            }
        }
    }

    /*
     * Match RTL: a separate FP32 multiply, then FP32 add,
     * accumulating columns in increasing order.
     *
     * Volatile intermediates also make the two rounding points
     * explicit in this reference implementation.
     */
    for (uint32_t i = 0; i < rows; ++i) {
        volatile float acc = 0.0f;

        check_interrupt();

        for (uint32_t j = 0; j < cols; ++j) {
            volatile float product =
                host_w[(size_t)i * cols + j] * host_x[j];

            acc = acc + product;
        }

        host_y[i] = acc;
    }

    if (pattern == PAT_CLASSIC) {
        static const float expected[4] = {
            30.0f, 70.0f, 110.0f, 150.0f
        };

        if (rows != 4 || cols != 4)
            fail("Internal error: classic test must be 4x4.");

        for (unsigned i = 0; i < 4; ++i) {
            if (float_bits(host_y[i]) != float_bits(expected[i]))
                fail("CPU reference failed the classic 4x4 test.");
        }
    }
}

static void load_ddr(void)
{
    require_all_idle();
    initialize_guards();

    for (size_t i = 0; i < bufs[0].words; ++i) {
        if ((i & 4095u) == 0)
            check_interrupt();

        bufs[0].data[i] = float_bits(host_w[i]);
    }

    for (size_t i = 0; i < bufs[1].words; ++i)
        bufs[1].data[i] = float_bits(host_x[i]);

    for (size_t i = 0; i < bufs[2].words; ++i)
        bufs[2].data[i] = output_poison(i);

    memory_barrier();

    check_inputs();
    check_poison();
    check_guards();
}

/* ------------------------------------------------------------
 * Configure, clear old completion, start and wait.
 * ------------------------------------------------------------ */

static void prepare_command(const struct config *cfg)
{
    const unsigned offsets[8] = {
        R_W_LO, R_W_HI, R_X_LO, R_X_HI,
        R_Y_LO, R_Y_HI, R_ROWS, R_COLS
    };

    const uint32_t values[8] = {
        (uint32_t)cfg->w, (uint32_t)(cfg->w >> 32),
        (uint32_t)cfg->x, (uint32_t)(cfg->x >> 32),
        (uint32_t)cfg->y, (uint32_t)(cfg->y >> 32),
        cfg->rows, cfg->cols
    };

    require_all_idle();

    for (unsigned i = 0; i < 8; ++i)
        write_check(offsets[i], values[i]);

    wr(R_CTRL, CTRL_CLEAR);

    if (rd(R_STATUS) != 0 || rd(R_CYCLES) != 0)
        fail("CLEAR did not clear STATUS/CYCLES.");

    /*
     * CLEAR must retain all configuration registers.
     */
    for (unsigned i = 0; i < 8; ++i) {
        if (rd(offsets[i]) != values[i])
            fail("CLEAR changed configuration register +0x%02x.",
                 offsets[i]);
    }
}

static void dump_progress(void)
{
    uint32_t status = rd(R_STATUS);
    uint32_t debug = rd(R_DEBUG);
    uint32_t cycles = rd(R_CYCLES);
    uint32_t row = rd(R_ROW_INDEX);
    uint32_t col = rd(R_COL_INDEX);

    fprintf(stderr,
        "STATUS=0x%08" PRIx32
        " DEBUG=0x%08" PRIx32
        " state=%" PRIu32
        " CYCLES=%" PRIu32
        " ROW=%" PRIu32
        " COL=%" PRIu32 "\n",
        status, debug, debug & 15u, cycles, row, col);
}

static struct run_result start_and_wait(uint32_t expected_status,
                                       uint64_t limit_ms)
{
    const struct timespec pause_time = {
        .tv_sec = 0,
        .tv_nsec = 100000
    };

    struct run_result result;
    uint64_t start;
    uint32_t status;

    require_all_idle();
    check_interrupt();

    start = now_us();

    /*
     * Mark uncertain before issuing START, so any later failure
     * warns that hardware completion has not been confirmed.
     */
    in_flight = true;
    wr(R_CTRL, CTRL_START);

    for (;;) {
        check_interrupt();
        status = rd(R_STATUS);

        /*
         * Do not require observing BUSY=1:
         * small commands may finish before the first poll.
         *
         * Do not stop merely because ERROR=1 while BUSY=1:
         * a malformed response may still be draining.
         */
        if (!(status & ST_BUSY) && (status & ST_DONE)) {
            in_flight = false;
            break;
        }

        if (now_us() - start >= limit_ms * UINT64_C(1000)) {
            dump_progress();
            fail("Timeout after %" PRIu64 " ms. No retry and no CLEAR.",
                 limit_ms);
        }

        if (nanosleep(&pause_time, NULL) != 0 && errno != EINTR)
            fail("nanosleep: %s", strerror(errno));
    }

    memory_barrier();

    result.wall_ms = (double)(now_us() - start) / 1000.0;
    result.cycles = rd(R_CYCLES);

    if (status != expected_status) {
        dump_progress();
        fail("Unexpected final STATUS: got 0x%08" PRIx32
             ", expected 0x%08" PRIx32,
             status, expected_status);
    }

    if (expected_status == ST_OK &&
        (result.cycles == 0 || result.cycles == UINT32_MAX))
        fail("Invalid/saturated normal-operation CYCLES=%" PRIu32,
             result.cycles);

    return result;
}

/* ------------------------------------------------------------
 * One complete test.
 *
 * If bad_config != NULL:
 *   payload buffers remain ordinary 4x4 buffers,
 *   but the supplied invalid CSR configuration is tested.
 * ------------------------------------------------------------ */

static void run_case(const char *name,
                     uint32_t rows, uint32_t cols,
                     enum pattern pattern, uint32_t seed,
                     const struct config *bad_config)
{
    struct config normal = {
        rows, cols, W_PHYS, X_PHYS, Y_PHYS
    };

    const struct config *cfg = bad_config ? bad_config : &normal;
    struct run_result result;
    size_t mismatches = 0;

    if (rows == 0 || cols == 0 || (rows & 3u) || (cols & 3u))
        fail("Internal invalid payload shape.");

    if (rows > max_rows || cols > max_cols) {
        printf("[SKIP] %s: %" PRIu32 "x%" PRIu32
               " exceeds configured hardware limits.\n",
               name, rows, cols);
        ++skipped;
        return;
    }

    printf("\n[RUN] %s  payload=%" PRIu32 "x%" PRIu32
           " seed=0x%08" PRIx32 "\n",
           name, rows, cols, seed);

    if (bad_config) {
        printf("      invalid request: ROWS=%" PRIu32
               " COLS=%" PRIu32
               " W=0x%016" PRIx64
               " X=0x%016" PRIx64
               " Y=0x%016" PRIx64 "\n",
               cfg->rows, cfg->cols, cfg->w, cfg->x, cfg->y);
    }

    require_all_idle();
    setup_buffers(rows, cols);
    generate_inputs(rows, cols, pattern, seed);
    load_ddr();
    prepare_command(cfg);

    result = start_and_wait(
        bad_config ? ST_PARAM_DONE : ST_OK,
        bad_config && timeout_ms > 1000 ? 1000 : timeout_ms
    );

    /*
     * Completion is confirmed before any DDR result reads.
     */
    require_all_idle();
    check_guards();
    check_inputs();

    if (bad_config) {
        check_poison();

        /*
         * ST_VALIDATE consumes a cycle in this RTL.
         * Do not require CYCLES=0 on parameter errors.
         */
        printf("[PASS] %s STATUS=0x0000000e"
               " CYCLES=%" PRIu32
               " input/output/guards unchanged\n",
               name, result.cycles);
    } else {
        if (rd(R_ROW_INDEX) != rows - 1 ||
            rd(R_COL_INDEX) != cols - 1) {
            dump_progress();
            fail("Final ROW_INDEX/COL_INDEX mismatch.");
        }

        for (size_t i = 0; i < bufs[2].words; ++i) {
            uint32_t got = bufs[2].data[i];
            uint32_t want = float_bits(host_y[i]);

            if (!same_result(got, want)) {
                if (mismatches < 8) {
                    fprintf(stderr,
                        "Y[%zu]: got=0x%08" PRIx32 " (%g)"
                        " expected=0x%08" PRIx32 " (%g)\n",
                        i, got, (double)bits_float(got),
                        want, (double)host_y[i]);
                }
                ++mismatches;
            } else if (pattern == PAT_CLASSIC) {
                printf("      y[%zu] = %g, bits=0x%08" PRIx32
                       " PASS\n", i, (double)bits_float(got), got);
            }
        }

        if (mismatches != 0)
            fail("%zu output mismatches in %s.", mismatches, name);

        printf("[PASS] %s STATUS=0x00000002"
               " CYCLES=%" PRIu32
               " host_wait=%.3f ms, outputs=%" PRIu32 "\n",
               name, result.cycles, result.wall_ms, rows);
    }

    ++passed;
    release_case();
}

/* ------------------------------------------------------------
 * Test suites.
 * ------------------------------------------------------------ */

static void run_basic_suite(void)
{
    struct test {
        const char *name;
        uint32_t rows;
        uint32_t cols;
        enum pattern pattern;
        uint32_t seed;
    };

    static const struct test tests[] = {
        { "classic_4x4",      4,  4, PAT_CLASSIC,  1 },
        { "identity_4x4",     4,  4, PAT_IDENTITY, 2 },
        { "zero_W_4x8",       4,  8, PAT_ZERO_W,   3 },
        { "zero_X_8x4",       8,  4, PAT_ZERO_X,   4 },
        { "cancel_4x8",       4,  8, PAT_CANCEL,   5 },
        { "random_4x8",       4,  8, PAT_RANDOM,   6 },
        { "random_8x4",       8,  4, PAT_RANDOM,   7 },
        { "random_8x8",       8,  8, PAT_RANDOM,   8 },
        { "random_12x20",    12, 20, PAT_RANDOM,   9 },
        { "random_16x16",    16, 16, PAT_RANDOM,  10 },
        { "random_32x64_A",  32, 64, PAT_RANDOM,  11 },
        { "random_64x256",   64,256, PAT_RANDOM,  12 },
        { "random_32x64_B",  32, 64, PAT_RANDOM,  13 },
        { "random_32x64_A2", 32, 64, PAT_RANDOM,  11 },
        { "classic_again",   4,  4, PAT_CLASSIC,  1 }
    };

    for (size_t i = 0; i < sizeof(tests) / sizeof(tests[0]); ++i) {
        run_case(tests[i].name, tests[i].rows, tests[i].cols,
                 tests[i].pattern, tests[i].seed, NULL);
    }
}

static void run_extended_suite(void)
{
    run_case("extended_128x128", 128, 128,
             PAT_RANDOM, 101, NULL);

    run_case("extended_288x768", 288, 768,
             PAT_RANDOM, 102, NULL);

    run_case("extended_768x288", 768, 288,
             PAT_RANDOM, 103, NULL);

    run_case("column_limit", 4, max_cols,
             PAT_RANDOM, 104, NULL);

    run_case("row_limit", max_rows, 4,
             PAT_RANDOM, 105, NULL);

    run_case("small_after_limits", 4, 4,
             PAT_CLASSIC, 1, NULL);
}

static void run_negative_suite(void)
{
    struct negative_test {
        const char *name;
        struct config cfg;
    };

    const struct negative_test tests[] = {
        { "reject_ROWS_3",  {3, 4, W_PHYS,     X_PHYS,     Y_PHYS} },
        { "reject_COLS_3",  {4, 3, W_PHYS,     X_PHYS,     Y_PHYS} },
        { "reject_W_align",{4, 4, W_PHYS + 4, X_PHYS,     Y_PHYS} },
        { "reject_X_align",{4, 4, W_PHYS,     X_PHYS + 4, Y_PHYS} },
        { "reject_Y_align",{4, 4, W_PHYS,     X_PHYS,     Y_PHYS + 4} },
        { "reject_Y_W",    {4, 4, W_PHYS,     X_PHYS,     W_PHYS} },
        { "reject_Y_X",    {4, 4, W_PHYS,     X_PHYS,     X_PHYS} },
        { "reject_ROWS_0", {0, 4, W_PHYS,     X_PHYS,     Y_PHYS} },
        { "reject_COLS_0", {4, 0, W_PHYS,     X_PHYS,     Y_PHYS} }
    };

    puts("\n[INFO] Starting explicitly requested negative tests.");
    puts("[INFO] No out-of-DDR physical addresses are injected.");

    for (size_t i = 0; i < sizeof(tests) / sizeof(tests[0]); ++i) {
        run_case(tests[i].name, 4, 4,
                 PAT_CLASSIC, 1, &tests[i].cfg);
    }

    /* Verify a valid command still works after parameter errors. */
    run_case("recovery_after_param_errors", 4, 4,
             PAT_CLASSIC, 1, NULL);
}

/* ------------------------------------------------------------
 * Command line and main.
 * ------------------------------------------------------------ */

static void usage(const char *program)
{
    printf(
        "Usage:\n"
        "  %s CSR_BASE [options]\n"
        "\n"
        "Options:\n"
        "  --extended           Add larger and dimension-limit tests\n"
        "  --negative           Add deliberate invalid-parameter tests\n"
        "  --shape ROWS COLS    Run one random shape instead of basic suite\n"
        "  --timeout-ms N       Normal command timeout, default 60000\n"
        "  --help               Show this help\n"
        "\n"
        "CSR_BASE must be the actual HPS physical CSR base from Address Map.\n"
        "This program does not discover or probe possible base addresses.\n",
        program
    );
}

int main(int argc, char **argv)
{
    uint64_t csr_base;
    bool extended = false;
    bool negative = false;
    bool custom_shape = false;
    uint32_t custom_rows = 0;
    uint32_t custom_cols = 0;
    struct sigaction sa;
    const uint32_t endian_test = 1;

    setvbuf(stdout, NULL, _IOLBF, 0);

    if (argc < 2) {
        usage(argv[0]);
        return EXIT_FAILURE;
    }

    if (strcmp(argv[1], "--help") == 0) {
        usage(argv[0]);
        return EXIT_SUCCESS;
    }

    csr_base = parse_u64(argv[1]);

    for (int i = 2; i < argc; ++i) {
        if (strcmp(argv[i], "--extended") == 0) {
            extended = true;
        } else if (strcmp(argv[i], "--negative") == 0) {
            negative = true;
        } else if (strcmp(argv[i], "--shape") == 0) {
            if (i + 2 >= argc)
                fail("--shape requires ROWS and COLS.");

            custom_rows = parse_u32(argv[++i]);
            custom_cols = parse_u32(argv[++i]);
            custom_shape = true;
        } else if (strcmp(argv[i], "--timeout-ms") == 0) {
            if (i + 1 >= argc)
                fail("--timeout-ms requires a value.");

            timeout_ms = parse_u64(argv[++i]);

            if (timeout_ms < 1 || timeout_ms > 600000)
                fail("--timeout-ms must be in 1..600000.");
        } else if (strcmp(argv[i], "--help") == 0) {
            usage(argv[0]);
            return EXIT_SUCCESS;
        } else {
            fail("Unknown option: %s", argv[i]);
        }
    }

    if (csr_base == 0 || (csr_base & UINT64_C(0xFFF)) != 0 ||
        csr_base > (uint64_t)INT64_MAX - 4096)
        fail("CSR_BASE must be a valid 4 KiB-aligned physical address.");

    if (csr_base == OLD_GEMV_BASE ||
        csr_base == DDR_BASE ||
        csr_base == FP32_BASE)
        fail("CSR_BASE is an existing component, not the new variable GEMV.");

    if (custom_shape &&
        (custom_rows == 0 || custom_cols == 0 ||
         (custom_rows & 3u) || (custom_cols & 3u)))
        fail("--shape requires positive multiples of four.");

    if (*(const unsigned char *)&endian_test != 1 ||
        float_bits(1.0f) != UINT32_C(0x3F800000))
        fail("This test requires the expected little-endian FP32 layout.");

    if (geteuid() != 0)
        fail("Run as root, for example with sudo.");

    if (fesetround(FE_TONEAREST) != 0)
        fail("Cannot select round-to-nearest.");

    if (atexit(cleanup) != 0)
        fail("Cannot register cleanup.");

    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);

    if (sigaction(SIGINT, &sa, NULL) != 0 ||
        sigaction(SIGTERM, &sa, NULL) != 0)
        fail("Cannot install signal handlers: %s", strerror(errno));

    require_reserved_memory();

    lock_fd = open(LOCK_PATH,
                   O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW,
                   0600);

    if (lock_fd < 0)
        fail("Cannot open lock file: %s", strerror(errno));

    if (flock(lock_fd, LOCK_EX | LOCK_NB) != 0)
        fail("Shared DDR test lock is held or unavailable: %s",
             strerror(errno));

    mem_fd = open("/dev/mem", O_RDWR | O_SYNC | O_CLOEXEC);

    if (mem_fd < 0)
        fail("open /dev/mem: %s", strerror(errno));

    printf("Variable GEMV CSR: 0x%016" PRIx64 "\n", csr_base);
    printf("W data address   : 0x%016" PRIx64 "\n", W_PHYS);
    printf("X data address   : 0x%016" PRIx64 "\n", X_PHYS);
    printf("Y data address   : 0x%016" PRIx64 "\n", Y_PHYS);
    printf("Timeout          : %" PRIu64 " ms per normal command\n",
           timeout_ms);

    puts("WARNING: shared DDR test buffers will be overwritten.");
    puts("Run all board tests serially; the lock is cooperative only.");

    map_slot(0, csr_base,     0x1000);
    map_slot(1, OLD_GEMV_BASE,0x1000);
    map_slot(2, DDR_BASE,     0x1000);
    map_slot(3, FP32_BASE,    0x1000);

    check_identity();

    if (custom_shape) {
        if (custom_rows > max_rows || custom_cols > max_cols)
            fail("Requested shape exceeds hardware limits.");

        run_case("custom_shape", custom_rows, custom_cols,
                 PAT_RANDOM, UINT32_C(0x12345678), NULL);
    } else {
        run_basic_suite();
    }

    if (extended)
        run_extended_suite();

    if (negative)
        run_negative_suite();

    if (skipped != 0) {
        printf("\n[PASS] %u tests passed; %u tests skipped "
               "because of configured hardware limits.\n",
               passed, skipped);
    } else {
        printf("\n[ALL PASS] %u tests passed.\n", passed);
    }

    puts("No RTL reset or automatic START retry was used.");
    return EXIT_SUCCESS;
}