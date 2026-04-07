// ops_fpga_sim.c
// FPGA 加速接口 —— 模拟/占位版本
//
// 使用方法:
//   1. 先用 ops.c 的纯 C 版本验证正确性
//   2. 在 FPGA 上实现某个算子后，在这里替换对应函数
//   3. 通过 PCIe/AXI 与 FPGA 通信
//
// 真实 FPGA 通信流程:
//   CPU                          FPGA
//    │                             │
//    │── 写入输入数据到共享内存 ──►  │
//    │── 写控制寄存器(启动) ──────►  │
//    │                             │── 计算
//    │◄── 中断/轮询(完成) ─────────│
//    │◄── 读取输出数据 ────────────│

#include "ops.h"
#include <stdio.h>
#include <string.h>

// ============================================
// FPGA 设备抽象
// ============================================
typedef struct {
    int      fd;           // 设备文件描述符
    void    *mmap_base;    // MMIO 映射基地址
    float   *dma_buf_in;   // DMA 输入缓冲
    float   *dma_buf_out;  // DMA 输出缓冲
    int      initialized;
} FPGADevice;

static FPGADevice fpga_dev = {0};

// FPGA 寄存器地址 (示例，根据你的 FPGA 设计修改)
#define REG_CTRL       0x00   // 控制: bit0=start, bit1=done
#define REG_OP_TYPE    0x04   // 操作类型: 0=matmul, 1=softmax, ...
#define REG_DIM_IN     0x08   // 输入维度
#define REG_DIM_OUT    0x0C   // 输出维度
#define REG_STATUS     0x10   // 状态

// 操作类型编码
#define FPGA_OP_MATMUL     0
#define FPGA_OP_RMSNORM    1
#define FPGA_OP_SOFTMAX    2
#define FPGA_OP_SILU       3
#define FPGA_OP_ROPE       4
#define FPGA_OP_VECADD     5
#define FPGA_OP_ELEMMUL    6
#define FPGA_OP_MATMUL_Q8  7

// ============================================
// FPGA 初始化/通信函数 (占位)
// ============================================
int fpga_init(const char *device_path) {
    printf("[FPGA] 初始化设备: %s\n", device_path);
    // 真实实现:
    //   fpga_dev.fd = open(device_path, O_RDWR);
    //   fpga_dev.mmap_base = mmap(...);
    //   分配 DMA 缓冲区
    fpga_dev.initialized = 1;
    printf("[FPGA] 模拟模式 (使用 CPU 回退)\n");
    return 0;
}

void fpga_close(void) {
    if (fpga_dev.initialized) {
        // munmap, close, free DMA buffers
        fpga_dev.initialized = 0;
        printf("[FPGA] 设备已关闭\n");
    }
}

// 写寄存器 (占位)
static void fpga_write_reg(uint32_t addr, uint32_t val) {
    (void)addr; (void)val;
    // 真实: *(volatile uint32_t*)(fpga_dev.mmap_base + addr) = val;
}

// 读寄存器 (占位)
static uint32_t fpga_read_reg(uint32_t addr) {
    (void)addr;
    return 1;  // 模拟: 总是返回 "done"
    // 真实: return *(volatile uint32_t*)(fpga_dev.mmap_base + addr);
}

// DMA 传输 (占位)
static void fpga_dma_write(const float *data, int n_floats) {
    (void)data; (void)n_floats;
    // 真实: memcpy(fpga_dev.dma_buf_in, data, n_floats * sizeof(float));
    //       然后触发 DMA 传输
}

static void fpga_dma_read(float *data, int n_floats) {
    (void)data; (void)n_floats;
    // 真实: 等待 DMA 完成，然后
    //       memcpy(data, fpga_dev.dma_buf_out, n_floats * sizeof(float));
}

// ============================================
// FPGA 加速版算子
// 当前: CPU 回退实现
// 将来: 替换为真实 FPGA 调用
// ============================================

// FPGA 版矩阵乘法
// 这是最值得加速的算子
//
// FPGA 内部架构建议:
//
//   ┌─────────────────────────────────────┐
//   │         MatMul 加速器               │
//   │                                     │
//   │  ┌─────┐  ┌─────────────────────┐  │
//   │  │权重  │  │  PE PE PE PE ... PE │  │ ← DIM 个处理单元
//   │  │BRAM  │─►│  PE PE PE PE ... PE │  │
//   │  │      │  │  PE PE PE PE ... PE │  │
//   │  └─────┘  └─────────┬───────────┘  │
//   │                      │              │
//   │  输入向量 ──────────►│              │
//   │                      ▼              │
//   │              ┌──────────────┐       │
//   │              │  加法树累加   │       │
//   │              └──────┬───────┘       │
//   │                     ▼               │
//   │              输出向量                │
//   └─────────────────────────────────────┘
//
void fpga_matmul(const float *in, const float *weight,
                 float *out, int in_dim, int out_dim) {
    if (!fpga_dev.initialized) {
        // 回退到 CPU
        op_matmul(in, weight, out, in_dim, out_dim);
        return;
    }

    // 真实 FPGA 调用流程:
    //   1. 通过 DMA 发送输入向量
    //   fpga_dma_write(in, in_dim);
    //
    //   2. 设置控制寄存器
    //   fpga_write_reg(REG_OP_TYPE, FPGA_OP_MATMUL);
    //   fpga_write_reg(REG_DIM_IN,  in_dim);
    //   fpga_write_reg(REG_DIM_OUT, out_dim);
    //   fpga_write_reg(REG_CTRL,    1);  // start
    //
    //   3. 等待完成
    //   while (!(fpga_read_reg(REG_STATUS) & 1)) {}
    //
    //   4. 读回结果
    //   fpga_dma_read(out, out_dim);

    // 模拟模式: 用 CPU 计算
    op_matmul(in, weight, out, in_dim, out_dim);
}

// ============================================
// FPGA Verilog 参考 —— 向量点积模块
// ============================================
//
// 以下是一个最简单的 DIM=64 向量点积的 Verilog 框架
// 你可以作为 FPGA 开发的起点:
//
// ```verilog
// module dot_product #(
//     parameter DIM = 64,
//     parameter DATA_WIDTH = 16   // Q16 定点数
// )(
//     input  wire                    clk,
//     input  wire                    rst_n,
//     input  wire                    start,
//     input  wire [DATA_WIDTH-1:0]   vec_a [0:DIM-1],
//     input  wire [DATA_WIDTH-1:0]   vec_b [0:DIM-1],
//     output reg  [31:0]             result,
//     output reg                     done
// );
//
//     // 第一级: 并行乘法
//     wire [2*DATA_WIDTH-1:0] products [0:DIM-1];
//     genvar i;
//     generate
//         for (i = 0; i < DIM; i = i + 1) begin : MUL
//             assign products[i] = $signed(vec_a[i]) *
//                                  $signed(vec_b[i]);
//         end
//     endgenerate
//
//     // 第二级: 加法树 (6级, log2(64)=6)
//     // 简化写法，实际需要流水线寄存器
//     integer j;
//     reg [31:0] sum;
//     always @(posedge clk) begin
//         if (!rst_n) begin
//             result <= 0;
//             done   <= 0;
//         end else if (start) begin
//             sum = 0;
//             for (j = 0; j < DIM; j = j + 1)
//                 sum = sum + {{(32-2*DATA_WIDTH){products[j][2*DATA_WIDTH-1]}},
//                              products[j]};
//             result <= sum;
//             done   <= 1;
//         end else begin
//             done <= 0;
//         end
//     end
// endmodule
// ```
//

// ============================================
// 完整 FPGA 实现路线图
// ============================================
//
// 阶段1: 入门 (1-2周)
//   □ 在 FPGA 上实现定点向量加法
//   □ 通过 AXI-Lite 接口和 CPU 通信
//   □ 验证: op_vec_add 的 FPGA 版本 vs C 版本
//
// 阶段2: 核心 (2-4周)
//   □ 实现定点向量点积
//   □ 扩展为矩阵-向量乘法 (systolic array)
//   □ 权重存储在 BRAM 中
//   □ 通过 DMA 传输输入/输出向量
//
// 阶段3: 完整 (4-8周)
//   □ 添加 RMSNorm (需要 sqrt 近似)
//   □ 添加 Softmax (需要 exp 近似)
//   □ 添加 SiLU (需要 sigmoid 近似)
//   □ 添加 RoPE (需要 sin/cos, 用 CORDIC)
//
// 阶段4: 优化 (持续)
//   □ Q8 量化推理 (资源减半)
//   □ 流水线优化 (提高吞吐)
//   □ 多层支持 (权重换页)
//   □ 注意力 KV cache 管理
//
// 推荐 FPGA 开发板:
//   入门: Xilinx Artix-7 (Digilent Arty A7-100T, ~$130)
//         240 DSP48, 4.9Mb BRAM, 足够跑这个 tiny model
//   进阶: Xilinx Zynq-7020 (PYNQ-Z2, ~$120)
//         ARM CPU + FPGA, 有 Linux, 开发更方便
//   高端: Xilinx KV260 / Intel Agilex
//         适合更大模型

#endif // 结束 FPGA 相关代码
