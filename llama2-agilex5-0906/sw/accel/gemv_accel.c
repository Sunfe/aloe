#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64

#include "gemv_accel.h"

#include <errno.h>
#include <fcntl.h>
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

#define VAR_CSR   UINT64_C(0x20023000)
#define FIXED_CSR UINT64_C(0x20020000)
#define DDR_CSR   UINT64_C(0x20021000)
#define FP32_CSR  UINT64_C(0x20022000)

#define DDR_BEGIN UINT64_C(0xB8000000)
#define DDR_END   UINT64_C(0xC0000000)
#define W_PHYS    UINT64_C(0xB8000040)
#define X_PHYS    UINT64_C(0xBFF00000)
#define Y_PHYS    UINT64_C(0xBFF10000)

#define GUARD_WORDS 16u
#define GUARD_BYTES 64u
#define Y_POISON UINT32_C(0x7FC00000)
#define TIMEOUT_MS UINT64_C(60000)
#define LOCK_PATH "/run/de25_shared_ddr.lock"

enum {
    R_CTRL = 0x00, R_STATUS = 0x04,
    R_W_LO = 0x08, R_X_LO = 0x10, R_Y_LO = 0x18,
    R_CYCLES = 0x20, R_VERSION = 0x24, R_DEBUG = 0x28,
    R_ROWS = 0x2C, R_COLS = 0x30,
    R_MAX_ROWS = 0x34, R_MAX_COLS = 0x38,
    R_ROW_INDEX = 0x3C, R_COL_INDEX = 0x40
};

typedef struct {
    void *base;
    size_t length;
    volatile uint32_t *p;
} Mapping;

typedef struct {
    int mem_fd;
    int lock_fd;
    Mapping maps[7];       /* variable, fixed, DDR, FP32, W, x, y */
    uint32_t dim;
    size_t w_words;
    int ready;
    int in_flight;
} Accel;

static Accel g = { .mem_fd = -1, .lock_fd = -1 };

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

static uint64_t monotonic_ms(void)
{
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t) != 0)
        return UINT64_MAX;
    return (uint64_t)t.tv_sec * 1000 + (uint64_t)t.tv_nsec / 1000000;
}

static int check_cmdline(void)
{
    FILE *f = fopen("/proc/cmdline", "r");
    char line[4096];
    int count = 0;

    if (!f)
        return -1;
    if (!fgets(line, sizeof(line), f)) {
        fclose(f);
        return -1;
    }
    fclose(f);

    for (char *p = strtok(line, " \t\r\n"); p;
         p = strtok(NULL, " \t\r\n")) {
        if (strncmp(p, "mem=", 4) == 0) {
            if (strcmp(p, "mem=896M") != 0)
                return -1;
            ++count;
        }
    }
    return count == 1 ? 0 : -1;
}

static int map_physical(unsigned slot, uint64_t phys, size_t bytes)
{
    long page_size = sysconf(_SC_PAGESIZE);
    uint64_t aligned, delta;
    size_t length;
    void *base;

    if (page_size <= 0 || (page_size & (page_size - 1)) != 0)
        return -1;
    if (phys > INT64_MAX || bytes == 0)
        return -1;

    aligned = phys & ~((uint64_t)page_size - 1);
    delta = phys - aligned;
    if (bytes > SIZE_MAX - (size_t)delta - (size_t)page_size)
        return -1;

    length = (bytes + (size_t)delta + (size_t)page_size - 1) &
             ~((size_t)page_size - 1);
    base = mmap(NULL, length, PROT_READ | PROT_WRITE,
                MAP_SHARED, g.mem_fd, (off_t)aligned);
    if (base == MAP_FAILED)
        return -1;

    g.maps[slot].base = base;
    g.maps[slot].length = length;
    g.maps[slot].p =
        (volatile uint32_t *)((unsigned char *)base + delta);
    return 0;
}

static uint32_t guard_value(unsigned slot, unsigned index, int after)
{
    return UINT32_C(0x13579BDF) ^
           ((uint32_t)slot << 24) ^
           ((uint32_t)index * UINT32_C(0x9E3779B9)) ^
           (after ? UINT32_C(0xFFFF0000) : 0);
}

static volatile uint32_t *data(unsigned slot)
{
    return g.maps[slot].p + GUARD_WORDS;
}

static void set_guards(unsigned slot, size_t words)
{
    volatile uint32_t *p = g.maps[slot].p;
    for (unsigned i = 0; i < GUARD_WORDS; ++i) {
        p[i] = guard_value(slot, i, 0);
        p[GUARD_WORDS + words + i] = guard_value(slot, i, 1);
    }
}

static int guards_ok(unsigned slot, size_t words)
{
    volatile uint32_t *p = g.maps[slot].p;
    for (unsigned i = 0; i < GUARD_WORDS; ++i) {
        if (p[i] != guard_value(slot, i, 0) ||
            p[GUARD_WORDS + words + i] != guard_value(slot, i, 1))
            return 0;
    }
    return 1;
}

static int all_idle(void)
{
    for (unsigned slot = 0; slot < 4; ++slot)
        if (reg_read(slot, R_STATUS) & 1u)
            return 0;
    return 1;
}

static int write_checked(unsigned offset, uint32_t value)
{
    reg_write(offset, value);
    return reg_read(0, offset) == value ? 0 : -1;
}

static int address_checked(unsigned offset, uint64_t addr)
{
    return write_checked(offset, (uint32_t)addr) == 0 &&
           write_checked(offset + 4, (uint32_t)(addr >> 32)) == 0
           ? 0 : -1;
}

static void print_status(void)
{
    fprintf(stderr,
            "GEMV STATUS=0x%08" PRIx32
            " DEBUG=0x%08" PRIx32
            " CYCLES=%" PRIu32
            " ROW=%" PRIu32 " COL=%" PRIu32 "\n",
            reg_read(0, R_STATUS), reg_read(0, R_DEBUG),
            reg_read(0, R_CYCLES),
            reg_read(0, R_ROW_INDEX), reg_read(0, R_COL_INDEX));
}

void gemv_accel_close(void)
{
    if (g.in_flight) {
        fprintf(stderr,
                "GEMV completion unconfirmed: closing this process "
                "cannot cancel the FPGA AXI transaction.\n");
    }

    for (unsigned i = 0; i < 7; ++i) {
        if (g.maps[i].base)
            munmap(g.maps[i].base, g.maps[i].length);
    }
    if (g.mem_fd >= 0)
        close(g.mem_fd);
    if (g.lock_fd >= 0)
        close(g.lock_fd);

    g = (Accel){ .mem_fd = -1, .lock_fd = -1 };
}

int gemv_accel_open(uint32_t dim)
{
    uint64_t w_bytes, vector_bytes;

    if (g.ready || g.mem_fd >= 0 || g.lock_fd >= 0)
        return -1;
    if (check_cmdline() != 0) {
        fprintf(stderr, "GEMV requires exactly one mem=896M argument\n");
        return -1;
    }

    if (dim < 4 || dim > 8192 || (dim & 3u)) {
        fprintf(stderr, "Unsupported model dim=%" PRIu32 "\n", dim);
        return -1;
    }

    w_bytes = (uint64_t)dim * dim * sizeof(float);
    vector_bytes = (uint64_t)dim * sizeof(float);

    /* Check full guarded windows, not just their starting addresses. */
    if (W_PHYS < DDR_BEGIN + GUARD_BYTES ||
        W_PHYS + w_bytes + GUARD_BYTES > X_PHYS - GUARD_BYTES ||
        X_PHYS + vector_bytes + GUARD_BYTES > Y_PHYS - GUARD_BYTES ||
        Y_PHYS + vector_bytes + GUARD_BYTES > DDR_END) {
        fprintf(stderr, "GEMV buffers do not fit nonoverlapping DDR windows\n");
        return -1;
    }

    g.lock_fd = open(LOCK_PATH,
                     O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (g.lock_fd < 0 ||
        flock(g.lock_fd, LOCK_EX | LOCK_NB) != 0) {
        fprintf(stderr, "Cannot acquire shared-DDR cooperative lock\n");
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
        fprintf(stderr, "Cannot map CSR registers\n");
        goto error;
    }

    if (reg_read(0, R_VERSION) != UINT32_C(0x47564D31) ||
        reg_read(1, R_VERSION) != UINT32_C(0x474D5631) ||
        reg_read(3, 0x18) != UINT32_C(0x46500001) ||
        dim > reg_read(0, R_MAX_ROWS) ||
        dim > reg_read(0, R_MAX_COLS) ||
        !all_idle()) {
        fprintf(stderr, "Unexpected image, hardware limit, or BUSY state\n");
        goto error;
    }
    /* The DDR test component has no VERSION register. */

    if (map_physical(4, W_PHYS - GUARD_BYTES,
                     (size_t)w_bytes + 2 * GUARD_BYTES) ||
        map_physical(5, X_PHYS - GUARD_BYTES,
                     (size_t)vector_bytes + 2 * GUARD_BYTES) ||
        map_physical(6, Y_PHYS - GUARD_BYTES,
                     (size_t)vector_bytes + 2 * GUARD_BYTES)) {
        fprintf(stderr, "Cannot map shared DDR buffers\n");
        goto error;
    }

    g.dim = dim;
    g.w_words = (size_t)dim * dim;
    g.ready = 1;
    fprintf(stderr, "GEMV ready: CSR=0x%08" PRIx64
                    ", dim=%" PRIu32 ", square Wq verification\n",
            VAR_CSR, dim);
    return 0;

error:
    gemv_accel_close();
    return -1;
}

int gemv_accel_run(float *y, const float *x, const float *w,
                   uint32_t rows, uint32_t cols)
{
    volatile uint32_t *dw, *dx, *dy;
    uint64_t start;
    uint32_t status;

    if (!g.ready || !y || !x || !w ||
        rows != g.dim || cols != g.dim || !all_idle()) {
        fprintf(stderr, "Invalid GEMV call or another component is BUSY\n");
        return -1;
    }

    dw = data(4);
    dx = data(5);
    dy = data(6);
    set_guards(4, g.w_words);
    set_guards(5, cols);
    set_guards(6, rows);

    for (size_t i = 0; i < g.w_words; ++i)
        dw[i] = fp_bits(w[i]);
    for (uint32_t i = 0; i < cols; ++i)
        dx[i] = fp_bits(x[i]);
    for (uint32_t i = 0; i < rows; ++i)
        dy[i] = Y_POISON;
    barrier();

    for (size_t i = 0; i < g.w_words; ++i)
        if (dw[i] != fp_bits(w[i]))
            goto data_error;
    for (uint32_t i = 0; i < cols; ++i)
        if (dx[i] != fp_bits(x[i]))
            goto data_error;

    if (!guards_ok(4, g.w_words) ||
        !guards_ok(5, cols) || !guards_ok(6, rows))
        goto data_error;

    if (address_checked(R_W_LO, W_PHYS) ||
        address_checked(R_X_LO, X_PHYS) ||
        address_checked(R_Y_LO, Y_PHYS) ||
        write_checked(R_ROWS, rows) ||
        write_checked(R_COLS, cols))
        goto csr_error;

    reg_write(R_CTRL, 4); /* CLEAR only while idle. */
    if (reg_read(0, R_STATUS) != 0 ||
        !all_idle())
        goto csr_error;

    start = monotonic_ms();
    if (start == UINT64_MAX)
        goto csr_error;

    /* Mark uncertain before START: a failed/blocked MMIO write is ambiguous. */
    g.in_flight = 1;
    reg_write(R_CTRL, 1);

    for (;;) {
        struct timespec pause_time = { .tv_sec = 0, .tv_nsec = 100000 };
        status = reg_read(0, R_STATUS);

        if (!(status & 1u) && (status & 2u)) {
            g.in_flight = 0;
            break;
        }
        uint64_t current = monotonic_ms();
        if (current == UINT64_MAX || current - start >= TIMEOUT_MS) {
            fprintf(stderr, "GEMV timeout; no CLEAR or retry\n");
            print_status();
            return -1;
        }
        nanosleep(&pause_time, NULL);
    }

    if (status != 2u ||
        reg_read(0, R_ROW_INDEX) != rows - 1 ||
        reg_read(0, R_COL_INDEX) != cols - 1) {
        fprintf(stderr, "GEMV completed with unexpected status/index\n");
        print_status();
        return -1;
    }

    barrier();
    if (!guards_ok(4, g.w_words) ||
        !guards_ok(5, cols) || !guards_ok(6, rows))
        goto data_error;

    for (size_t i = 0; i < g.w_words; ++i)
        if (dw[i] != fp_bits(w[i]))
            goto data_error;
    for (uint32_t i = 0; i < cols; ++i)
        if (dx[i] != fp_bits(x[i]))
            goto data_error;

    for (uint32_t i = 0; i < rows; ++i) {
        uint32_t u = dy[i];
        if (u == Y_POISON) {
            fprintf(stderr, "GEMV y[%" PRIu32 "] remains unwritten\n", i);
            return -1;
        }
        memcpy(&y[i], &u, sizeof(u));
    }

    fprintf(stderr, "GEMV FP32: rows=%" PRIu32 " cols=%" PRIu32
                    " cycles=%" PRIu32 "\n",
            rows, cols, reg_read(0, R_CYCLES));
    return 0;

data_error:
    fprintf(stderr, "GEMV DDR data or guard verification failed\n");
    return -1;
csr_error:
    fprintf(stderr, "GEMV CSR write/readback or CLEAR failed\n");
    return -1;
}