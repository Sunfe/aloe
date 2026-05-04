/* SPDX-License-Identifier: MIT */
#ifndef FPGA_GEMV_H
#define FPGA_GEMV_H

#include <stdint.h>
#include <stddef.h>

struct fpga_gemv_desc {
	uint64_t w_addr;
	uint64_t x_addr;
	uint64_t y_addr;
	uint32_t n_real;
	uint32_t n_pad;
	uint32_t d_out;
	uint32_t stride_w; /* in float elements */
};

struct fpga_gemv_ctx {
	int uio_fd;
	void *mmio;
	size_t mmio_size;
	int irq_mode;
};

/* return 0 on success, negative errno on failure */
int fpga_gemv_init(struct fpga_gemv_ctx *ctx, const char *uio_dev, size_t mmio_size);
void fpga_gemv_deinit(struct fpga_gemv_ctx *ctx);

int fpga_gemv_soft_reset(struct fpga_gemv_ctx *ctx);
int fpga_gemv_run(struct fpga_gemv_ctx *ctx, const struct fpga_gemv_desc *d, int timeout_ms);

uint32_t fpga_gemv_read_err(struct fpga_gemv_ctx *ctx);

#endif /* FPGA_GEMV_H */