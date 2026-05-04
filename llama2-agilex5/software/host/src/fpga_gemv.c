/* SPDX-License-Identifier: MIT */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "fpga_gemv.h"
#include "fpga_gemv_regs.h"

static inline uint32_t reg_read32(struct fpga_gemv_ctx *ctx, uint32_t off)
{
	volatile uint32_t *p = (volatile uint32_t *)((char *)ctx->mmio + off);
	return *p;
}

static inline void reg_write32(struct fpga_gemv_ctx *ctx, uint32_t off, uint32_t val)
{
	volatile uint32_t *p = (volatile uint32_t *)((char *)ctx->mmio + off);
	*p = val;
}

static int is_aligned_64(uint64_t addr)
{
	return (addr & 0x3fULL) == 0;
}

static int wait_done_poll(struct fpga_gemv_ctx *ctx, int timeout_ms)
{
	struct timespec ts0, ts1;
	long elapsed_ms = 0;

	if (clock_gettime(CLOCK_MONOTONIC, &ts0) < 0)
		return -errno;

	while (1) {
		uint32_t st = reg_read32(ctx, GEMV_REG_STATUS);

		if (st & GEMV_STATUS_ERROR)
			return -EIO;
		if (st & GEMV_STATUS_DONE)
			return 0;

		usleep(100);

		if (clock_gettime(CLOCK_MONOTONIC, &ts1) < 0)
			return -errno;

		elapsed_ms = (ts1.tv_sec - ts0.tv_sec) * 1000L +
			     (ts1.tv_nsec - ts0.tv_nsec) / 1000000L;
		if (elapsed_ms > timeout_ms)
			return -ETIMEDOUT;
	}
}

int fpga_gemv_init(struct fpga_gemv_ctx *ctx, const char *uio_dev, size_t mmio_size)
{
	if (!ctx || !uio_dev || mmio_size == 0)
		return -EINVAL;

	memset(ctx, 0, sizeof(*ctx));
	ctx->uio_fd = -1;
	ctx->mmio_size = mmio_size;
	ctx->irq_mode = 0;

	ctx->uio_fd = open(uio_dev, O_RDWR | O_SYNC);
	if (ctx->uio_fd < 0)
		return -errno;

	ctx->mmio = mmap(NULL, mmio_size, PROT_READ | PROT_WRITE, MAP_SHARED,
			 ctx->uio_fd, 0);
	if (ctx->mmio == MAP_FAILED) {
		int err = -errno;
		close(ctx->uio_fd);
		ctx->uio_fd = -1;
		ctx->mmio = NULL;
		return err;
	}

	return 0;
}

void fpga_gemv_deinit(struct fpga_gemv_ctx *ctx)
{
	if (!ctx)
		return;

	if (ctx->mmio && ctx->mmio != MAP_FAILED)
		munmap(ctx->mmio, ctx->mmio_size);
	if (ctx->uio_fd >= 0)
		close(ctx->uio_fd);

	ctx->mmio = NULL;
	ctx->uio_fd = -1;
	ctx->mmio_size = 0;
}

int fpga_gemv_soft_reset(struct fpga_gemv_ctx *ctx)
{
	if (!ctx || !ctx->mmio)
		return -EINVAL;

	reg_write32(ctx, GEMV_REG_CTRL, GEMV_CTRL_SRESET);
	usleep(50);

	return 0;
}

uint32_t fpga_gemv_read_err(struct fpga_gemv_ctx *ctx)
{
	if (!ctx || !ctx->mmio)
		return 0xffffffffU;

	return reg_read32(ctx, GEMV_REG_ERR_CODE);
}

int fpga_gemv_run(struct fpga_gemv_ctx *ctx, const struct fpga_gemv_desc *d, int timeout_ms)
{
	uint32_t st;
	int ret;

	if (!ctx || !ctx->mmio || !d)
		return -EINVAL;
	if (timeout_ms <= 0)
		return -EINVAL;
	if (d->n_real == 0 || d->n_pad == 0 || d->d_out == 0 || d->stride_w == 0)
		return -EINVAL;
	if (d->n_pad < d->n_real)
		return -EINVAL;

	/* V1 alignment policy: 64B aligned addresses */
	if (!is_aligned_64(d->w_addr) || !is_aligned_64(d->x_addr) || !is_aligned_64(d->y_addr))
		return -EINVAL;

	st = reg_read32(ctx, GEMV_REG_STATUS);
	if (st & GEMV_STATUS_BUSY)
		return -EBUSY;

	reg_write32(ctx, GEMV_REG_W_ADDR_L, (uint32_t)(d->w_addr & 0xffffffffULL));
	reg_write32(ctx, GEMV_REG_W_ADDR_H, (uint32_t)(d->w_addr >> 32));
	reg_write32(ctx, GEMV_REG_X_ADDR_L, (uint32_t)(d->x_addr & 0xffffffffULL));
	reg_write32(ctx, GEMV_REG_X_ADDR_H, (uint32_t)(d->x_addr >> 32));
	reg_write32(ctx, GEMV_REG_Y_ADDR_L, (uint32_t)(d->y_addr & 0xffffffffULL));
	reg_write32(ctx, GEMV_REG_Y_ADDR_H, (uint32_t)(d->y_addr >> 32));

	reg_write32(ctx, GEMV_REG_N_REAL, d->n_real);
	reg_write32(ctx, GEMV_REG_N_PAD, d->n_pad);
	reg_write32(ctx, GEMV_REG_D_OUT, d->d_out);
	reg_write32(ctx, GEMV_REG_STRIDE_W, d->stride_w);

	reg_write32(ctx, GEMV_REG_CFG, GEMV_CFG_FP32 | GEMV_CFG_ALIGN_CHK_EN);

	reg_write32(ctx, GEMV_REG_CTRL, GEMV_CTRL_START);

	ret = wait_done_poll(ctx, timeout_ms);
	if (ret < 0)
		return ret;

	st = reg_read32(ctx, GEMV_REG_STATUS);
	if (st & GEMV_STATUS_ERROR)
		return -EIO;

	return 0;
}