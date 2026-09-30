#ifndef GEMV_ACCEL_H
#define GEMV_ACCEL_H

#include <stdint.h>

/* This first integration supports only one dim x dim Wq matrix. */
int gemv_accel_open(uint32_t dim);
int gemv_accel_run(float *y, const float *x, const float *w,
                   uint32_t rows, uint32_t cols);
void gemv_accel_close(void);

#endif