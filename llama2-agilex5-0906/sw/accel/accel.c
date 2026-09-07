#define _GNU_SOURCE
#include "accel.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <time.h>

/* ---------------- 地址 (以 GHRD 地址表 / cat /proc/iomem 为准) ---------------- */
#define LWH2F_BASE   0x20000000UL     /* Agilex 5 HPS: LWHPS2FPGA 桥 */
#define H2F_BASE     0x40000000UL     /* Agilex 5 HPS: HPS2FPGA 桥 */
#define CSR_OFF      0x00000000UL     /* csr 在 LWH2F 中的偏移 (Platform Designer 分配) */
#define XBUF_OFF     0x00000000UL     /* x_buf 在 H2F 中的偏移 */
#define YBUF_OFF     0x00100000UL     /* y_buf 在 H2F 中的偏移 */
#define MEM_WIN_SIZE 0x00200000UL

#define WMEM_PHYS    0x60000000UL     /* 设备树 reserved-memory */
#define WMEM_SIZE    0x20000000UL     /* 512MB */

/* ---------------- 寄存器 (与 matvec_pkg.sv 一一对应) ---------------- */
#define R_CTRL     (0x00/4)
#define R_STATUS   (0x04/4)
#define R_WLO      (0x08/4)
#define R_WHI      (0x0C/4)
#define R_NROWS    (0x10/4)
#define R_DCOLS    (0x14/4)
#define R_SCALE    (0x18/4)
#define R_GROUP    (0x1C/4)
#define R_CYCLES   (0x20/4)
#define R_VERSION  (0x24/4)

#define CTRL_START   (1u<<0)
#define CTRL_IRQ_EN  (1u<<1)
#define CTRL_INT8    (1u<<2)
#define ST_BUSY      (1u<<0)
#define ST_DONE      (1u<<1)
#define ST_AXI_ERR   (1u<<2)

#define EXPECT_VERSION 0x20250001u
#define TIMEOUT_MS     2000

static int  fd = -1;
static volatile uint32_t *csr, *xbuf, *ybuf;
static volatile uint32_t *wmem;          /* 权重区 (device memory, 32bit 访问) */
static size_t wmem_used;

#define dsb() __asm__ volatile("dsb sy" ::: "memory")

static long now_ms(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec*1000 + t.tv_nsec/1000000;
}

int accel_open(void) {
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open /dev/mem"); return -1; }

    void *p;
    p = mmap(NULL, 0x1000, PROT_READ|PROT_WRITE, MAP_SHARED, fd, LWH2F_BASE + CSR_OFF);
    if (p == MAP_FAILED) { perror("mmap csr"); return -1; }
    csr = p;

    p = mmap(NULL, MEM_WIN_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd, H2F_BASE);
    if (p == MAP_FAILED) { perror("mmap h2f"); return -1; }
    xbuf = (volatile uint32_t *)((char *)p + XBUF_OFF);
    ybuf = (volatile uint32_t *)((char *)p + YBUF_OFF);

    p = mmap(NULL, WMEM_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, fd, WMEM_PHYS);
    if (p == MAP_FAILED) { perror("mmap wmem (reserved-memory 配好了吗?)"); return -1; }
    wmem = p; wmem_used = 0;

    uint32_t v = csr[R_VERSION];
    if (v != EXPECT_VERSION) {
        fprintf(stderr, "accel: VERSION=0x%08x, expected 0x%08x (bitstream 没烧对?)\n", v, EXPECT_VERSION);
        return -1;
    }
    csr[R_STATUS] = ST_DONE | ST_AXI_ERR;   /* 清残留状态 */
    return 0;
}

void accel_close(void) {
    if (csr)  munmap((void *)csr, 0x1000);
    if (xbuf) munmap((void *)((char *)xbuf - XBUF_OFF), MEM_WIN_SIZE);
    if (wmem) munmap((void *)wmem, WMEM_SIZE);
    if (fd >= 0) close(fd);
    csr = xbuf = ybuf = wmem = NULL; fd = -1;
}

float *accel_alloc_weights(size_t bytes, uint64_t *phys_out) {
    size_t off = (wmem_used + 63) & ~(size_t)63;
    if (off + bytes > WMEM_SIZE) {
        fprintf(stderr, "accel: 权重区不够 (need %zu, have %zu)\n", bytes, WMEM_SIZE - off);
        return NULL;
    }
    wmem_used = off + bytes;
    if (phys_out) *phys_out = WMEM_PHYS + off;
    return (float *)((char *)wmem + off);
}

/* device memory 上不能用 memcpy (NEON/非对齐访问会 Bus error), 逐字拷 */
void accel_copy_in(float *dst, const float *src, size_t n) {
    volatile uint32_t *d = (volatile uint32_t *)dst;
    const uint32_t *s = (const uint32_t *)src;
    for (size_t i = 0; i < n; i++) d[i] = s[i];
    dsb();
}

uint64_t accel_phys_of(const void *virt) {
    return WMEM_PHYS + ((const char *)virt - (const char *)wmem);
}

void accel_matvec(float *y, const float *x, uint64_t w_phys, int n, int d) {
    if (d % 8 != 0 || d < 32 || d > 8192 || n > 32768) {
        fprintf(stderr, "accel_matvec: unsupported shape n=%d d=%d\n", n, d);
        exit(EXIT_FAILURE);
    }

    /* 1. x -> x_buf */
    const uint32_t *xs = (const uint32_t *)x;
    for (int i = 0; i < d; i++) xbuf[i] = xs[i];
    dsb();

    /* 2. 配置并启动 */
    csr[R_WLO]   = (uint32_t)w_phys;
    csr[R_WHI]   = (uint32_t)(w_phys >> 32);
    csr[R_NROWS] = (uint32_t)n;
    csr[R_DCOLS] = (uint32_t)d;
    dsb();
    csr[R_CTRL]  = CTRL_START;

    /* 3. 轮询 DONE (阶段 3 改 UIO 中断) */
    long t0 = now_ms();
    uint32_t st;
    while (!((st = csr[R_STATUS]) & (ST_DONE | ST_AXI_ERR))) {
        if (now_ms() - t0 > TIMEOUT_MS) {
            fprintf(stderr, "accel_matvec: timeout, STATUS=0x%x CYCLES=%u\n", st, csr[R_CYCLES]);
            exit(EXIT_FAILURE);
        }
    }
    if (st & ST_AXI_ERR) {
        fprintf(stderr, "accel_matvec: AXI error reading 0x%llx\n", (unsigned long long)w_phys);
        exit(EXIT_FAILURE);
    }
    csr[R_STATUS] = ST_DONE;

    /* 4. y_buf -> y */
    uint32_t *yd = (uint32_t *)y;
    for (int i = 0; i < n; i++) yd[i] = ybuf[i];
}

uint32_t accel_version(void)     { return csr[R_VERSION]; }
uint32_t accel_last_cycles(void) { return csr[R_CYCLES]; }
