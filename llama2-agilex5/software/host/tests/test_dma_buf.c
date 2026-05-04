/* SPDX-License-Identifier: MIT */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "dma_buf.h"

int main(void)
{
	struct dma_buf w, x, y;
	int ret;
	size_t i;
	float *xf, *yf;

	ret = dma_buf_alloc(&w, 4096, 64);
	if (ret < 0) {
		fprintf(stderr, "alloc w failed: %d\n", ret);
		return 1;
	}

	ret = dma_buf_alloc(&x, 1024, 64);
	if (ret < 0) {
		fprintf(stderr, "alloc x failed: %d\n", ret);
		dma_buf_free(&w);
		return 1;
	}

	ret = dma_buf_alloc(&y, 1024, 64);
	if (ret < 0) {
		fprintf(stderr, "alloc y failed: %d\n", ret);
		dma_buf_free(&x);
		dma_buf_free(&w);
		return 1;
	}

	printf("w: v=%p p=0x%" PRIx64 " size=%zu\n", w.vaddr, w.paddr, w.size);
	printf("x: v=%p p=0x%" PRIx64 " size=%zu\n", x.vaddr, x.paddr, x.size);
	printf("y: v=%p p=0x%" PRIx64 " size=%zu\n", y.vaddr, y.paddr, y.size);

	if (((uintptr_t)w.vaddr & 0x3f) || ((uintptr_t)x.vaddr & 0x3f) ||
	    ((uintptr_t)y.vaddr & 0x3f)) {
		fprintf(stderr, "alignment check failed\n");
		ret = 1;
		goto out;
	}

	xf = (float *)x.vaddr;
	yf = (float *)y.vaddr;

	for (i = 0; i < x.size / sizeof(float); i++)
		xf[i] = (float)i * 0.5f;
	memset(yf, 0, y.size);

	ret = dma_buf_sync_for_device(&x, 0, x.size);
	if (ret < 0) {
		fprintf(stderr, "sync_for_device failed: %d\n", ret);
		ret = 1;
		goto out;
	}

	ret = dma_buf_sync_for_cpu(&y, 0, y.size);
	if (ret < 0) {
		fprintf(stderr, "sync_for_cpu failed: %d\n", ret);
		ret = 1;
		goto out;
	}

	printf("dma_buf smoke test pass\n");
	ret = 0;

out:
	dma_buf_free(&y);
	dma_buf_free(&x);
	dma_buf_free(&w);
	return ret;
}
