#include "accel.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define CLK_MHZ 100.0   /* 与 Platform Designer 里加速器时钟一致, 用于换算带宽 */

static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }

static int test(int n, int d) {
    float *W = malloc((size_t)n * d * 4), *x = malloc(d * 4), *y = malloc(n * 4);
    for (size_t i = 0; i < (size_t)n * d; i++) W[i] = ((rand() / (float)RAND_MAX) - 0.5f) * 0.1f;
    for (int i = 0; i < d; i++) x[i] = (rand() / (float)RAND_MAX) - 0.5f;

    uint64_t phys;
    float *wdev = accel_alloc_weights((size_t)n * d * 4, &phys);
    if (!wdev) return 1;
    accel_copy_in(wdev, W, (size_t)n * d);

    double t0 = now();
    accel_matvec(y, x, phys, n, d);
    double t_fpga = now() - t0;
    uint32_t cyc = accel_last_cycles();

    t0 = now();
    double max_rel = 0; int bad = 0;
    for (int r = 0; r < n; r++) {
        double ref = 0;
        for (int c = 0; c < d; c++) ref += (double)W[(size_t)r * d + c] * x[c];
        double rel = fabs(y[r] - ref) / (fabs(ref) + 1e-3);
        if (rel > max_rel) max_rel = rel;
        if (rel > 1e-4) { if (bad < 5) printf("  row %d: fpga %f ref %f\n", r, y[r], ref); bad++; }
    }
    double t_cpu = now() - t0;

    double bytes = (double)n * d * 4;
    printf("n=%-6d d=%-5d  %s  max_rel=%.2e  cycles=%u (%.2f B/cycle, %.2f GB/s)  wall: fpga %.3f ms, cpu(fp64) %.3f ms\n",
           n, d, bad ? "FAIL" : "PASS", max_rel, cyc, bytes / cyc, bytes / (cyc / (CLK_MHZ * 1e6)) / 1e9,
           t_fpga * 1e3, t_cpu * 1e3);
    free(W); free(x); free(y);
    return bad != 0;
}

int main(void) {
    if (accel_open() != 0) return 1;
    printf("accel VERSION=0x%08x\n", accel_version());
    int fails = 0;
    fails += test(256, 256);
    fails += test(768, 2048);    /* w1/w3 形状 */
    fails += test(2048, 768);    /* w2 形状 (d 不是 burst 整数倍) */
    fails += test(32000, 768);   /* wcls */
    accel_close();
    printf(fails ? "SELFTEST FAIL\n" : "SELFTEST PASS\n");
    return fails;
}