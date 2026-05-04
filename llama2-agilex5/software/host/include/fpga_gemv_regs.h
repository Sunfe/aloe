/* SPDX-License-Identifier: MIT */
#ifndef FPGA_GEMV_REGS_H
#define FPGA_GEMV_REGS_H

/* CSR offsets */
#define GEMV_REG_CTRL		0x00
#define GEMV_REG_STATUS		0x04
#define GEMV_REG_IRQ_EN		0x08
#define GEMV_REG_IRQ_ST		0x0C

#define GEMV_REG_W_ADDR_L	0x10
#define GEMV_REG_W_ADDR_H	0x14
#define GEMV_REG_X_ADDR_L	0x18
#define GEMV_REG_X_ADDR_H	0x1C
#define GEMV_REG_Y_ADDR_L	0x20
#define GEMV_REG_Y_ADDR_H	0x24

#define GEMV_REG_N_REAL		0x28
#define GEMV_REG_N_PAD		0x2C
#define GEMV_REG_D_OUT		0x30
#define GEMV_REG_STRIDE_W	0x34
#define GEMV_REG_CFG		0x38
#define GEMV_REG_ERR_CODE	0x3C

/**************** CTRL ****************/
#define GEMV_CTRL_START		(1U << 0)
#define GEMV_CTRL_SRESET	(1U << 1)

/**************** STATUS **************/
#define GEMV_STATUS_DONE	(1U << 0)
#define GEMV_STATUS_BUSY	(1U << 1)
#define GEMV_STATUS_ERROR	(1U << 2)

/**************** IRQ *****************/
#define GEMV_IRQ_DONE_EN	(1U << 0)
#define GEMV_IRQ_DONE_ST	(1U << 0)

/**************** CFG *****************/
#define GEMV_CFG_FP32		(1U << 0)
#define GEMV_CFG_ALIGN_CHK_EN	(1U << 1)

#endif /* FPGA_GEMV_REGS_H */