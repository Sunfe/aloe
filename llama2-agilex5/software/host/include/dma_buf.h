/* SPDX-License-Identifier: MIT */
#ifndef DMA_BUF_H
#define DMA_BUF_H

#include <stddef.h>
#include <stdint.h>

struct dma_buf {
	void *vaddr;		/* userspace virtual address */
	uint64_t paddr;		/* device-visible address (V1 fallback = vaddr cast) */
	size_t size;
	size_t align;
	int is_coherent;	/* 1: coherent, 0: need sync (platform dependent) */
};

int dma_buf_alloc(struct dma_buf *b, size_t size, size_t align);
void dma_buf_free(struct dma_buf *b);

/*
 * V1: placeholders. Later bind to real cache maintenance API/driver ioctl.
 * return 0 on success, negative errno on failure.
 */
int dma_buf_sync_for_device(struct dma_buf *b, size_t off, size_t len);
int dma_buf_sync_for_cpu(struct dma_buf *b, size_t off, size_t len);

#endif /* DMA_BUF_H */
