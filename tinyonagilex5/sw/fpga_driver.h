#ifndef FPGA_DRIVER_H
#define FPGA_DRIVER_H

#include <stdint.h>

// ============================================
// Agilex 5 HPS-FPGA Bridge 地址
// ============================================
// Agilex 5 地址映射 (参考 Intel Agilex 5 HPS TRM):
//
// Lightweight HPS-to-FPGA bridge:
//   HPS 地址: 0xF900_0000 ~ 0xF91F_FFFF (2MB)
//   用途: 控制寄存器 (AXI4-Lite)
//
// HPS-to-FPGA bridge:
//   HPS 地址: 0x0000_0000 ~ 0x3FFF_FFFF (1GB, 通过 FPGA2SDRAM)
//   用途: 大数据传输 (DMA)
//
// FPGA-to-SDRAM bridge:
//   FPGA 通过此桥直接读写 HPS DDR
//   用于加速器 DMA 访问权重和中间数据

// 基地址 (Agilex 5 specific)
#define LW_BRIDGE_BASE    0xF9000000UL   // Lightweight bridge
#define LW_BRIDGE_SIZE    0x00200000UL   // 2MB

// 加速器在 LW bridge 中的偏移
#define ACCEL_OFFSET      0x00000000UL

// 寄存器偏移 (和 axi_slave.sv 中一致)
#define REG_CTRL          0x000
#define REG_STATUS        0x004
#define REG_OP_TYPE       0x008
#define REG_PARAM0        0x00C
#define REG_PARAM1        0x010
#define REG_PARAM2        0x014
#define REG_SRC_ADDR      0x020
#define REG_WGT_ADDR      0x024
#define REG_DST_ADDR      0x028
#define REG_CYCLES        0x02C

// 操作类型 (和 RTL 中一致)
#define FPGA_OP_MATMUL      0
#define FPGA_OP_RMSNORM     1
#define FPGA_OP_SOFTMAX     2
#define FPGA_OP_SILU        3
#define FPGA_OP_ROPE        4
#define FPGA_OP_VECADD      5
#define FPGA_OP_ELEMMUL     6
#define FPGA_OP_ATTN_SCORE  7
#define FPGA_OP_ATTN_MIX    8

// 状态位
#define STATUS_BUSY         (1 << 0)
#define STATUS_DONE         (1 << 1)

// CTRL 位
#define CTRL_START          (1 << 0)
#define CTRL_IRQ_EN         (1 << 1)

// ============================================
// 驱动接口
// ============================================
typedef struct {
    int          fd;          // /dev/mem 文件描述符
    void        *lw_base;    // LW bridge mmap 基地址
    void        *accel_base; // 加速器寄存器基地址

    // DMA 缓冲区 (CMA 或预留内存)
    uint32_t     dma_phys;   // DMA 缓冲物理地址
    void        *dma_virt;   // DMA 缓冲虚拟地址
    uint32_t     dma_size;   // DMA 缓冲大小

    // 性能统计
    uint64_t     total_ops;
    uint64_t     total_cycles;
} FPGADriver;

// 初始化/关闭
int  fpga_driver_init(FPGADriver *drv);
void fpga_driver_close(FPGADriver *drv);

// 寄存器读写
void     fpga_reg_write(FPGADriver *drv, uint32_t offset, uint32_t value);
uint32_t fpga_reg_read(FPGADriver *drv, uint32_t offset);

// Bridge 使能 (Agilex 5 需要显式使能)
int fpga_enable_bridges(void);

// 执行加速操作
// 返回 FPGA 计算周期数
uint32_t fpga_execute_op(FPGADriver *drv,
                          uint32_t op_type,
                          uint32_t param0,
                          uint32_t param1,
                          uint32_t param2,
                          uint32_t src_phys,
                          uint32_t wgt_phys,
                          uint32_t dst_phys);

// DMA 缓冲管理
int  fpga_dma_alloc(FPGADriver *drv, uint32_t size);
void fpga_dma_free(FPGADriver *drv);
void fpga_dma_sync_to_device(FPGADriver *drv, uint32_t offset, uint32_t size);
void fpga_dma_sync_from_device(FPGADriver *drv, uint32_t offset, uint32_t size);

#endif
