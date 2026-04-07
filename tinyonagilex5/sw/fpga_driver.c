#include "fpga_driver.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <time.h>

// ============================================
// Agilex 5 Bridge 使能
// ============================================
// Agilex 5 的 HPS-FPGA bridge 需要在 Linux 中显式使能
// 通过 sysfs 或者 System Manager 寄存器

int fpga_enable_bridges(void) {
    // 方法 1: 通过 sysfs (推荐)
    // Agilex 5 Linux BSP 提供了 bridge 控制接口

    FILE *f;

    // 使能 LW HPS-to-FPGA bridge
    f = fopen("/sys/class/fpga_bridge/lwhps2fpga/enable", "w");
    if (f) {
        fprintf(f, "1");
        fclose(f);
        printf("[FPGA] LW HPS-to-FPGA bridge 已使能\n");
    } else {
        // 方法 2: 直接写 System Manager 寄存器
        // Agilex 5 System Manager 基地址: 0x10D12000
        // FPGA bridge 控制寄存器偏移取决于具体版本
        printf("[FPGA] 警告: 无法通过 sysfs 使能 bridge, 尝试 devmem\n");

        int fd = open("/dev/mem", O_RDWR | O_SYNC);
        if (fd < 0) {
            perror("[FPGA] 打开 /dev/mem 失败");
            return -1;
        }

        // Agilex 5 System Manager
        #define SYSMGR_BASE  0x10D12000UL
        #define SYSMGR_SIZE  0x1000
        // NOC bridge 控制 (具体偏移参考 Agilex 5 TRM)
        #define SYSMGR_NOC_CTRL  0x0

        void *sysmgr = mmap(NULL, SYSMGR_SIZE,
                            PROT_READ | PROT_WRITE,
                            MAP_SHARED, fd, SYSMGR_BASE);
        if (sysmgr == MAP_FAILED) {
            perror("[FPGA] mmap System Manager 失败");
            close(fd);
            return -1;
        }

        // 使能所有 bridge (具体位取决于 Agilex 5 版本)
        // 这里是示意，需要根据实际手册调整
        volatile uint32_t *ctrl = (volatile uint32_t *)
                                  ((char*)sysmgr + SYSMGR_NOC_CTRL);
        *ctrl |= 0x7;  // 使能 LW/HP/F2S bridge

        munmap(sysmgr, SYSMGR_SIZE);
        close(fd);
        printf("[FPGA] Bridge 已通过 System Manager 使能\n");
    }

    // 使能 HPS-to-FPGA bridge
    f = fopen("/sys/class/fpga_bridge/hps2fpga/enable", "w");
    if (f) {
        fprintf(f, "1");
        fclose(f);
        printf("[FPGA] HPS-to-FPGA bridge 已使能\n");
    }

    // 使能 FPGA-to-SDRAM bridge
    f = fopen("/sys/class/fpga_bridge/fpga2sdram/enable", "w");
    if (f) {
        fprintf(f, "1");
        fclose(f);
        printf("[FPGA] FPGA-to-SDRAM bridge 已使能\n");
    }

    return 0;
}

// ============================================
// 驱动初始化
// ============================================
int fpga_driver_init(FPGADriver *drv) {
    memset(drv, 0, sizeof(FPGADriver));

    printf("[FPGA] ===== Agilex 5 FPGA 驱动初始化 =====\n");

    // 使能 bridge
    if (fpga_enable_bridges() < 0) {
        return -1;
    }

    // 打开 /dev/mem
    drv->fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (drv->fd < 0) {
        perror("[FPGA] 打开 /dev/mem 失败");
        printf("[FPGA] 提示: 需要 root 权限，或使用 UIO 驱动\n");
        return -1;
    }

    // mmap Lightweight bridge
    drv->lw_base = mmap(NULL, LW_BRIDGE_SIZE,
                        PROT_READ | PROT_WRITE,
                        MAP_SHARED,
                        drv->fd, LW_BRIDGE_BASE);

    if (drv->lw_base == MAP_FAILED) {
        perror("[FPGA] mmap LW bridge 失败");
        close(drv->fd);
        return -1;
    }

    drv->accel_base = (char*)drv->lw_base + ACCEL_OFFSET;

    // 读取状态寄存器验证连接
    uint32_t status = fpga_reg_read(drv, REG_STATUS);
    printf("[FPGA] 加速器状态: 0x%08X\n", status);

    if (status == 0xDEADBEEF) {
        printf("[FPGA] 错误: 读到无效值，FPGA 可能未烧录\n");
        fpga_driver_close(drv);
        return -1;
    }

    printf("[FPGA] 驱动初始化成功\n");
    printf("[FPGA] LW Bridge 映射: %p\n", drv->lw_base);
    printf("[FPGA] 加速器基地址:   %p\n", drv->accel_base);

    return 0;
}

void fpga_driver_close(FPGADriver *drv) {
    if (drv->dma_virt) {
        fpga_dma_free(drv);
    }
    if (drv->lw_base && drv->lw_base != MAP_FAILED) {
        munmap(drv->lw_base, LW_BRIDGE_SIZE);
    }
    if (drv->fd > 0) {
        close(drv->fd);
    }

    printf("[FPGA] 驱动已关闭 (总操作: %llu, 总周期: %llu)\n",
          (unsigned long long)drv->total_ops,
          (unsigned long long)drv->total_cycles);
}

// ============================================
// 寄存器读写
// ============================================
void fpga_reg_write(FPGADriver *drv, uint32_t offset, uint32_t value) {
    volatile uint32_t *reg = (volatile uint32_t *)
                             ((char*)drv->accel_base + offset);
    *reg = value;
}

uint32_t fpga_reg_read(FPGADriver *drv, uint32_t offset) {
    volatile uint32_t *reg = (volatile uint32_t *)
                             ((char*)drv->accel_base + offset);
    return *reg;
}

// ============================================
// DMA 缓冲区管理
// ============================================
// Agilex 5 推荐使用 CMA (Contiguous Memory Allocator)
// 或者在设备树中预留一块物理连续内存

int fpga_dma_alloc(FPGADriver *drv, uint32_t size) {
    // 方法 1: 使用 CMA (/dev/cma)
    // 方法 2: 预留内存 (在设备树中指定)
    // 方法 3: 简单方案 — 用一块固定的高地址内存

    // 这里用简单方案: 预留物理地址 0x30000000 开始的区域
    // 需要在 U-Boot 或设备树中预留这块内存
    //   reserved-memory {
    //       fpga_dma: buffer@30000000 {
    //           reg = <0x30000000 0x1000000>;  // 16MB
    //           no-map;
    //       };
    //   };

    #define DMA_PHYS_BASE  0x30000000UL
    #define DMA_MAX_SIZE   0x01000000UL  // 16MB

    if (size > DMA_MAX_SIZE) {
        printf("[FPGA] DMA 缓冲过大: %u > %lu\n", size, (unsigned long)DMA_MAX_SIZE);
        return -1;
    }

    drv->dma_phys = DMA_PHYS_BASE;
    drv->dma_size = size;

    drv->dma_virt = mmap(NULL, size,
                         PROT_READ | PROT_WRITE,
                         MAP_SHARED,
                         drv->fd, DMA_PHYS_BASE);

    if (drv->dma_virt == MAP_FAILED) {
        perror("[FPGA] mmap DMA 缓冲失败");
        return -1;
    }

    printf("[FPGA] DMA 缓冲: phys=0x%08X virt=%p size=%u bytes\n",
           drv->dma_phys, drv->dma_virt, drv->dma_size);

    return 0;
}

void fpga_dma_free(FPGADriver *drv) {
    if (drv->dma_virt && drv->dma_virt != MAP_FAILED) {
        munmap(drv->dma_virt, drv->dma_size);
        drv->dma_virt = NULL;
    }
}

// Cache 同步 (ARM 端)
void fpga_dma_sync_to_device(FPGADriver *drv, uint32_t offset, uint32_t size) {
    // ARM Cache flush
    // 在 Linux 用户态，对 mmap O_SYNC 的内存，写入即可见
    // 如果用 cacheable 映射，需要:
    //   __builtin___clear_cache(addr, addr + size);
    (void)drv; (void)offset; (void)size;
}

void fpga_dma_sync_from_device(FPGADriver *drv, uint32_t offset, uint32_t size) {
    // ARM Cache invalidate
    (void)drv; (void)offset; (void)size;
}

// ============================================
// 执行 FPGA 操作
// ============================================
uint32_t fpga_execute_op(FPGADriver *drv,
                          uint32_t op_type,
                          uint32_t param0,
                          uint32_t param1,
                          uint32_t param2,
                          uint32_t src_phys,
                          uint32_t wgt_phys,
                          uint32_t dst_phys) {

    // 1. 配置参数寄存器
    fpga_reg_write(drv, REG_OP_TYPE,  op_type);
    fpga_reg_write(drv, REG_PARAM0,   param0);
    fpga_reg_write(drv, REG_PARAM1,   param1);
    fpga_reg_write(drv, REG_PARAM2,   param2);
    fpga_reg_write(drv, REG_SRC_ADDR, src_phys);
    fpga_reg_write(drv, REG_WGT_ADDR, wgt_phys);
    fpga_reg_write(drv, REG_DST_ADDR, dst_phys);

    // 2. 启动
    fpga_reg_write(drv, REG_CTRL, CTRL_START);

    // 3. 等待完成 (轮询)
    uint32_t timeout = 10000000;  // 超时保护
    uint32_t status;
    do {
        status = fpga_reg_read(drv, REG_STATUS);
        timeout--;
    } while (!(status & STATUS_DONE) && timeout > 0);

    if (timeout == 0) {
        printf("[FPGA] 错误: 操作超时! op=%u status=0x%X\n",
               op_type, status);
        return 0xFFFFFFFF;
    }

    // 4. 读取性能计数
    uint32_t cycles = fpga_reg_read(drv, REG_CYCLES);

    drv->total_ops++;
    drv->total_cycles += cycles;

    return cycles;
}
