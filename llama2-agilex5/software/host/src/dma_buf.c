/* SPDX-License-Identifier: MIT */
#define _GNU_SOURCE
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "dma_buf.h"

static int is_pow2(size_t x)
{
	return x && ((x & (x - 1)) == 0);
}

int dma_buf_alloc(struct dma_buf *b, size_t size, size_t align)
{
	void *ptr;
	int ret;

	if (!b || !size)
		return -EINVAL;
	if (!align)
		align = 64;
	if (!is_pow2(align))
		return -EINVAL;

	memset(b, 0, sizeof(*b));

	ret = posix_memalign(&ptr, align, size);
	if (ret)
		return -ret;

	memset(ptr, 0, size);

	b->vaddr = ptr;
	b->size = size;
	b->align = align;

	/*
	 * V1 fallback:
	 * No IOMMU/CMA integration yet, use virtual address cast as placeholder.
	 * Must be replaced by real device-visible physical/IOVA address later.
	 */
	b->paddr = (uint64_t)(uintptr_t)ptr;
	b->is_coherent = 0;

	return 0;
}

void dma_buf_free(struct dma_buf *b)
{
	if (!b)
		return;

	if (b->vaddr)
		free(b->vaddr);

	memset(b, 0, sizeof(*b));
}

int dma_buf_sync_for_device(struct dma_buf *b, size_t off, size_t len)
{
	if (!b || !b->vaddr)
		return -EINVAL;
	if (off > b->size || len > b->size - off)
		return -EINVAL;

	/* V1 no-op; V2 use ioctl/syscall to flush cache lines. */
	__sync_synchronize();
	return 0;
}

int dma_buf_sync_for_cpu(struct dma_buf *b, size_t off, size_t len)
{
	if (!b || !b->vaddr)
		return -EINVAL;
	if (off > b->size || len > b->size - off)
		return -EINVAL;

	/* V1 no-op; V2 use ioctl/syscall to invalidate cache lines. */
	__sync_synchronize();
	return 0;
}
