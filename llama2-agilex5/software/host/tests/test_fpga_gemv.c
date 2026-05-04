/* SPDX-License-Identifier: MIT */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#include "fpga_gemv.h"

int main(int argc, char **argv)
{
	struct fpga_gemv_ctx ctx;
	struct fpga_gemv_desc d;
	int ret;

	if (argc < 2) {
		fprintf(stderr, "usage: %s /dev/uioX\n", argv[0]);
		return 1;
	}

	ret = fpga_gemv_init(&ctx, argv[1], 0x1000);
	if (ret < 0) {
		fprintf(stderr, "fpga_gemv_init failed: %d\n", ret);
		return 1;
	}

	ret = fpga_gemv_soft_reset(&ctx);
	if (ret < 0) {
		fprintf(stderr, "soft_reset failed: %d\n", ret);
		goto out;
	}

	/* NOTE: fake addresses for smoke test only */
	d.w_addr = 0x10000000ULL;
	d.x_addr = 0x10010000ULL;
	d.y_addr = 0x10020000ULL;
	d.n_real = 128;
	d.n_pad = 128;
	d.d_out = 128;
	d.stride_w = 128;

	ret = fpga_gemv_run(&ctx, &d, 1000);
	if (ret < 0) {
		fprintf(stderr, "fpga_gemv_run failed: %d, hw_err=0x%x\n",
			ret, fpga_gemv_read_err(&ctx));
		goto out;
	}

	printf("gemv run success\n");

out:
	fpga_gemv_deinit(&ctx);
	return ret < 0 ? 1 : 0;
}