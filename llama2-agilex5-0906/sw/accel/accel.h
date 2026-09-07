#ifndef ACCEL_H
#define ACCEL_H
#include <stdint.h>
#include <stddef.h>

int     accel_open(void);
void    accel_close(void);

/* 在 reserved 权重区顺序分配 (64B 对齐), 返回虚拟地址, phys_out 返回物理地址 */
float  *accel_alloc_weights(size_t bytes, uint64_t *phys_out);
/* 把普通内存拷进权重区 (只能用 32bit 访存, 不能 memcpy) */
void    accel_copy_in(float *dst, const float *src, size_t n_floats);
/* 权重区内虚拟地址 -> 物理地址 */
uint64_t accel_phys_of(const void *virt);

/* y[n] = W[n][d] * x[d], w_phys 为权重物理地址 */
void    accel_matvec(float *y, const float *x, uint64_t w_phys, int n, int d);

uint32_t accel_version(void);
uint32_t accel_last_cycles(void);
#endif
