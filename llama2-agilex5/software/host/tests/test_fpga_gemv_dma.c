/* SPDX-License-Identifier: MIT */
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dma_buf.h"
#include "fpga_gemv.h"

static void fill_test_data(float *w, float *x, float *y, uint32_t d, uint32_t n_pad)
{
	uint32_t i, j;

	/* simple deterministic values */
	for (i = 0; i < d; i++) {
		for (j = 0; j < n_pad; j++)
			w[i * n_pad + j] = (float)((i + j) % 13) * 0.01f;
	}

	for (j = 0; j < n_pad; j++)
		x[j] = (float)(j % 7) * 0.1f;

	memset(y, 0, sizeof(float) * d);
}

int main(int argc, char **argv)
{
	struct fpga_gemv_ctx ctx;
	struct fpga_gemv_desc desc;
	struct dma_buf wbuf, xbuf, ybuf;
	float *w, *x, *y;
	uint32_t n_real = 128;
	uint32_t n_pad = 128;
	uint32_t d_out = 128;
	size_t w_size = (size_t)d_out * n_pad * sizeof(float);
	size_t x_size = (size_t)n_pad * sizeof(float);
	size_t y_size = (size_t)d_out * sizeof(float);
	int ret;
	int i;

	if (argc < 2) {
		fprintf(stderr, "usage: %s /dev/uioX\n", argv[0]);
		return 1;
	}

	memset(&ctx, 0, sizeof(ctx));
	memset(&wbuf, 0, sizeof(wbuf));
	memset(&xbuf, 0, sizeof(xbuf));
	memset(&ybuf, 0, sizeof(ybuf));

	ret = fpga_gemv_init(&ctx, argv[1], 0x1000);
	if (ret < 0) {
		fprintf(stderr, "fpga_gemv_init failed: %d\n", ret);
		return 1;
	}

	ret = fpga_gemv_soft_reset(&ctx);
	if (ret < 0) {
		fprintf(stderr, "fpga_gemv_soft_reset failed: %d\n", ret);
		goto out_ctx;
	}

	ret = dma_buf_alloc(&wbuf, w_size, 64);
	if (ret < 0) {
		fprintf(stderr, "dma_buf_alloc w failed: %d\n", ret);
		goto out_ctx;
	}

	ret = dma_buf_alloc(&xbuf, x_size, 64);
	if (ret < 0) {
		fprintf(stderr, "dma_buf_alloc x failed: %d\n", ret);
		goto out_w;
	}

	ret = dma_buf_alloc(&ybuf, y_size, 64);
	if (ret < 0) {
		fprintf(stderr, "dma_buf_alloc y failed: %d\n", ret);
		goto out_x;
	}

	w = (float *)wbuf.vaddr;
	x = (float *)xbuf.vaddr;
	y = (float *)ybuf.vaddr;

	fill_test_data(w, x, y, d_out, n_pad);

	ret = dma_buf_sync_for_device(&wbuf, 0, wbuf.size);
	if (ret < 0) {
		fprintf(stderr, "sync w failed: %d\n", ret);
		goto out_y;
	}
	ret = dma_buf_sync_for_device(&xbuf, 0, xbuf.size);
	if (ret < 0) {
		fprintf(stderr, "sync x failed: %d\n", ret);
		goto out_y;
	}
	ret = dma_buf_sync_for_device(&ybuf, 0, ybuf.size);
	if (ret < 0) {
		fprintf(stderr, "sync y failed: %d\n", ret);
		goto out_y;
	}

	desc.w_addr = wbuf.paddr;
	desc.x_addr = xbuf.paddr;
	desc.y_addr = ybuf.paddr;
	desc.n_real = n_real;
	desc.n_pad = n_pad;
	desc.d_out = d_out;
	desc.stride_w = n_pad;

	printf("run gemv: W=0x%llx X=0x%llx Y=0x%llx n=%u/%u d=%u\n",
	       (unsigned long long)desc.w_addr,
	       (unsigned long long)desc.x_addr,
	       (unsigned long long)desc.y_addr,
	       desc.n_real, desc.n_pad, desc.d_out);

	ret = fpga_gemv_run(&ctx, &desc, 2000);
	if (ret < 0) {
		fprintf(stderr, "fpga_gemv_run failed: %d, hw_err=0x%x\n",
			ret, fpga_gemv_read_err(&ctx));
		goto out_y;
	}

	ret = dma_buf_sync_for_cpu(&ybuf, 0, ybuf.size);
	if (ret < 0) {
		fprintf(stderr, "sync y for cpu failed: %d\n", ret);
		goto out_y;
	}

	printf("gemv done, y[0..7]:\n");
	for (i = 0; i < 8 && i < (int)d_out; i++)
		printf("  y[%d] = %.6f\n", i, y[i]);

	printf("test_fpga_gemv_dma pass (pipeline)\n");

out_y:
	dma_buf_free(&ybuf);
out_x:
	dma_buf_free(&xbuf);
out_w:
	dma_buf_free(&wbuf);
out_ctx:
	fpga_gemv_deinit(&ctx);

	return ret < 0 ? 1 : 0;
}
