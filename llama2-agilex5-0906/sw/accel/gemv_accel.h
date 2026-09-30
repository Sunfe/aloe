#ifndef GEMV_ACCEL_H
#define GEMV_ACCEL_H

#include <stdint.h>

/*
 * Timings for the most recent successful accelerator call.
 * All software durations are in nanoseconds.
 */
typedef struct {
    uint64_t preflight_ns;
    uint64_t prepare_ns;
    uint64_t w_copy_ns;
    uint64_t x_copy_ns;
    uint64_t precheck_ns;
    uint64_t config_ns;
    uint64_t wait_ns;
    uint64_t completion_ns;
    uint64_t postcheck_ns;
    uint64_t y_copy_ns;
    uint64_t total_ns;

    uint32_t cycles;
} GemvAccelTiming;

/* Current host integration supports dim x dim matrices. */
int gemv_accel_open(uint32_t dim);

int gemv_accel_run(
    float *y,
    const float *x,
    const float *w,
    uint32_t rows,
    uint32_t cols
);

int gemv_accel_get_last_timing(GemvAccelTiming *out);

/* Shared monotonic clock for software profiling. */
uint64_t gemv_accel_now_ns(void);

void gemv_accel_close(void);

#endif