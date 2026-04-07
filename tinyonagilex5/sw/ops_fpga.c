// ops_fpga.c
// 通过 FPGA 硬件执行算子
// 接口和 ops_cpu.c 完全一致，可无缝替换

#include "ops.h"
#include "fpga_driver.h"
#include "tiny_llm_gguf.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

// 全局 FPGA 驱动实例
static FPGADriver g_fpga = {0};
static int g_fpga_ready = 0;

// ============================================
// DMA 缓冲区布局
// ============================================
// 偏移       大小        用途
// 0x000000   16KB       输入向量
// 0x004000   256KB      权重矩阵
// 0x044000   16KB       输出向量
// 0x048000   64KB       KV cache K
// 0x058000   64KB       KV cache V
// 0x068000   剩余       临时缓冲

#define DMA_OFS_INPUT    0x000000
#define DMA_OFS_WEIGHT   0x004000
#define DMA_OFS_OUTPUT   0x044000
#define DMA_OFS_KCACHE   0x048000
#define DMA_OFS_VCACHE   0x058000
#define DMA_OFS_TEMP     0x068000

// Q16 定点数转换
static inline int16_t float_to_q16(float f) {
    int v = (int)(f * 256.0f);  // FRAC_W = 8
    if (v > 32767) v = 32767;
    if (v < -32768) v = -32768;
    return (int16_t)v;
}

static inline float q16_to_float(int16_t q) {
    return (float)q / 256.0f;
}

// ============================================
// FPGA 初始化
// ============================================
int ops_fpga_init(void) {
    printf("[OPS_FPGA] 初始化 FPGA 加速...\n");

    if (fpga_driver_init(&g_fpga) < 0) {
        printf("[OPS_FPGA] FPGA 初始化失败，回退到 CPU\n");
        g_fpga_ready = 0;
        return -1;
    }

    // 分配 1MB DMA 缓冲
    if (fpga_dma_alloc(&g_fpga, 1 * 1024 * 1024) < 0) {
        printf("[OPS_FPGA] DMA 分配失败\n");
        fpga_driver_close(&g_fpga);
        g_fpga_ready = 0;
        return -1;
    }

    g_fpga_ready = 1;
    printf("[OPS_FPGA] 初始化成功\n");
    return 0;
}

void ops_fpga_close(void) {
    if (g_fpga_ready) {
        fpga_driver_close(&g_fpga);
        g_fpga_ready = 0;
    }
}

// ============================================
// FPGA 加速矩阵乘法
// ============================================
void op_matmul(const float *in, const float *weight,
               float *out, int in_dim, int out_dim) {

    if (!g_fpga_ready) {
        // CPU 回退
        for (int o = 0; o < out_dim; o++) {
            float sum = 0.0f;
            for (int i = 0; i < in_dim; i++)
                sum += in[i] * weight[i * out_dim + o];
            out[o] = sum;
        }
        return;
    }

    // ---- FPGA 加速路径 ----

    // 1. 将输入 float32 转为 Q16 定点数，写入 DMA 缓冲
    int16_t *dma_in = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_INPUT);
    for (int i = 0; i < in_dim; i++) {
        dma_in[i] = float_to_q16(in[i]);
    }

    // 2. 将权重 float32 转为 Q16，写入 DMA 缓冲
    int16_t *dma_wgt = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_WEIGHT);
    for (int i = 0; i < in_dim * out_dim; i++) {
        dma_wgt[i] = float_to_q16(weight[i]);
    }

    // 3. 同步 cache
    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_INPUT,
                            in_dim * sizeof(int16_t));
    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_WEIGHT,
                            in_dim * out_dim * sizeof(int16_t));

    // 4. 提交到 FPGA
    uint32_t cycles = fpga_execute_op(
        &g_fpga,
        FPGA_OP_MATMUL,
        (uint32_t)in_dim,               // param0
        (uint32_t)out_dim,              // param1
        0,                               // param2
        g_fpga.dma_phys + DMA_OFS_INPUT,
        g_fpga.dma_phys + DMA_OFS_WEIGHT,
        g_fpga.dma_phys + DMA_OFS_OUTPUT
    );

    // 5. 从 DMA 读回结果，Q16 转 float32
    fpga_dma_sync_from_device(&g_fpga, DMA_OFS_OUTPUT,
                               out_dim * sizeof(int32_t));

    int32_t *dma_out = (int32_t*)((char*)g_fpga.dma_virt + DMA_OFS_OUTPUT);
    for (int i = 0; i < out_dim; i++) {
        out[i] = (float)dma_out[i] / 256.0f;  // 反量化
    }

    (void)cycles;  // 可用于性能分析
}

// ============================================
// FPGA 加速 RMSNorm
// ============================================
void op_rmsnorm(const float *x, const float *weight,
                float *out, int dim, float eps) {

    if (!g_fpga_ready) {
        // CPU 回退
        float sum_sq = 0.0f;
        for (int i = 0; i < dim; i++) sum_sq += x[i] * x[i];
        float inv_rms = 1.0f / sqrtf(sum_sq / (float)dim + eps);
        for (int i = 0; i < dim; i++) out[i] = x[i] * inv_rms * weight[i];
        return;
    }

    // 写入输入和权重
    int16_t *dma_in  = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_INPUT);
    int16_t *dma_wgt = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_WEIGHT);
    for (int i = 0; i < dim; i++) {
        dma_in[i]  = float_to_q16(x[i]);
        dma_wgt[i] = float_to_q16(weight[i]);
    }

    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_INPUT, dim * 2);
    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_WEIGHT, dim * 2);

    fpga_execute_op(&g_fpga, FPGA_OP_RMSNORM,
                    (uint32_t)dim, 0, 0,
                    g_fpga.dma_phys + DMA_OFS_INPUT,
                    g_fpga.dma_phys + DMA_OFS_WEIGHT,
                    g_fpga.dma_phys + DMA_OFS_OUTPUT);

    fpga_dma_sync_from_device(&g_fpga, DMA_OFS_OUTPUT, dim * 4);
    int32_t *dma_out = (int32_t*)((char*)g_fpga.dma_virt + DMA_OFS_OUTPUT);
    for (int i = 0; i < dim; i++)
        out[i] = (float)dma_out[i] / 256.0f;
}

// ============================================
// FPGA 加速 Softmax
// ============================================
void op_softmax(float *x, int n) {
    if (!g_fpga_ready) {
        float max_val = x[0];
        for (int i = 1; i < n; i++)
            if (x[i] > max_val) max_val = x[i];
        float sum = 0.0f;
        for (int i = 0; i < n; i++) {
            x[i] = expf(x[i] - max_val);
            sum += x[i];
        }
        for (int i = 0; i < n; i++) x[i] /= sum;
        return;
    }

    int16_t *dma_in = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_INPUT);
    for (int i = 0; i < n; i++)
        dma_in[i] = float_to_q16(x[i]);

    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_INPUT, n * 2);

    fpga_execute_op(&g_fpga, FPGA_OP_SOFTMAX,
                    (uint32_t)n, 0, 0,
                    g_fpga.dma_phys + DMA_OFS_INPUT,
                    0,
                    g_fpga.dma_phys + DMA_OFS_OUTPUT);

    fpga_dma_sync_from_device(&g_fpga, DMA_OFS_OUTPUT, n * 4);
    int32_t *dma_out = (int32_t*)((char*)g_fpga.dma_virt + DMA_OFS_OUTPUT);
    for (int i = 0; i < n; i++)
        x[i] = (float)dma_out[i] / 256.0f;
}

// ============================================
// FPGA 加速 SiLU
// ============================================
void op_silu(float *x, int n) {
    if (!g_fpga_ready) {
        for (int i = 0; i < n; i++) {
            float sigmoid = 1.0f / (1.0f + expf(-x[i]));
            x[i] = x[i] * sigmoid;
        }
        return;
    }

    int16_t *dma_in = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_INPUT);
    for (int i = 0; i < n; i++)
        dma_in[i] = float_to_q16(x[i]);

    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_INPUT, n * 2);

    fpga_execute_op(&g_fpga, FPGA_OP_SILU,
                    (uint32_t)n, 0, 0,
                    g_fpga.dma_phys + DMA_OFS_INPUT, 0,
                    g_fpga.dma_phys + DMA_OFS_OUTPUT);

    fpga_dma_sync_from_device(&g_fpga, DMA_OFS_OUTPUT, n * 4);
    int32_t *dma_out = (int32_t*)((char*)g_fpga.dma_virt + DMA_OFS_OUTPUT);
    for (int i = 0; i < n; i++)
        x[i] = (float)dma_out[i] / 256.0f;
}

// ============================================
// FPGA 加速 RoPE
// ============================================
void op_rope(float *q, float *k, int dim, int pos) {
    if (!g_fpga_ready) {
        for (int i = 0; i < dim / 2; i++) {
            float freq = 1.0f / powf(10000.0f, (float)(2*i) / (float)dim);
            float theta = (float)pos * freq;
            float c = cosf(theta), s = sinf(theta);
            float q0=q[2*i], q1=q[2*i+1];
            q[2*i]=q0*c-q1*s; q[2*i+1]=q0*s+q1*c;
            float k0=k[2*i], k1=k[2*i+1];
            k[2*i]=k0*c-k1*s; k[2*i+1]=k0*s+k1*c;
        }
        return;
    }

    // Q 和 K 连续放入 DMA: [q0..q63, k0..k63]
    int16_t *dma_in = (int16_t*)((char*)g_fpga.dma_virt + DMA_OFS_INPUT);
    for (int i = 0; i < dim; i++) {
        dma_in[i]       = float_to_q16(q[i]);
        dma_in[dim + i] = float_to_q16(k[i]);
    }

    fpga_dma_sync_to_device(&g_fpga, DMA_OFS_INPUT, dim * 2 * 2);

    fpga_execute_op(&g_fpga, FPGA_OP_ROPE,
                    (uint32_t)dim, (uint32_t)pos, 0,
                    g_fpga.dma_phys + DMA_OFS_INPUT, 0,
                    g_fpga.dma_phys + DMA_OFS_OUTPUT);

    fpga_dma_sync_from_device(&g_fpga, DMA_OFS_OUTPUT, dim * 2 * 4);
    int32_t *dma_out = (int32_t*)((char*)g_fpga.dma_virt + DMA_OFS_OUTPUT);
    for (int i = 0; i < dim; i++) {
        q[i] = (float)dma_out[i] / 256.0f;
        k[i] = (float)dma_out[dim + i] / 256.0f;
    }
}

// 其他算子类似模式...
// op_vec_add, op_elem_mul, op_relu, op_argmax
// 这些太简单，FPGA 加速收益小，建议保留 CPU 实现

void op_vec_add(const float *a, const float *b, float *out, int n) {
    for (int i = 0; i < n; i++) out[i] = a[i] + b[i];
}

void op_elem_mul(const float *a, const float *b, float *out, int n) {
    for (int i = 0; i < n; i++) out[i] = a[i] * b[i];
}

void op_relu(float *x, int n) {
    for (int i = 0; i < n; i++) if (x[i] < 0) x[i] = 0;
}

int op_argmax(const float *x, int n) {
    int m = 0;
    for (int i = 1; i < n; i++) if (x[i] > x[m]) m = i;
    return m;
}

void op_attention_scores(const float *q, const float *k_cache,
                         float *scores, int dim, int seq_len) {
    float scale = 1.0f / sqrtf((float)dim);
    for (int t = 0; t < seq_len; t++) {
        float dot = 0.0f;
        for (int i = 0; i < dim; i++)
            dot += q[i] * k_cache[t * dim + i];
        scores[t] = dot * scale;
    }
}

void op_attention_mix(const float *weights, const float *v_cache,
                      float *out, int dim, int seq_len) {
    memset(out, 0, sizeof(float) * dim);
    for (int t = 0; t < seq_len; t++) {
        float w = weights[t];
        for (int i = 0; i < dim; i++)
            out[i] += w * v_cache[t * dim + i];
    }
}

// 量化算子保持 CPU 实现
void op_quantize_q8(const float *in, QuantizedVec *out, int n) {
    float amax = 0;
    for (int i = 0; i < n; i++) {
        float a = fabsf(in[i]);
        if (a > amax) amax = a;
    }
    float scale = amax / 127.0f;
    if (scale == 0) scale = 1.0f;
    out->scale = scale;
    out->n = n;
    if (!out->data) out->data = (int8_t*)malloc(n);
    float inv = 1.0f / scale;
    for (int i = 0; i < n; i++) {
        int v = (int)roundf(in[i] * inv);
        if (v > 127) v = 127; if (v < -128) v = -128;
        out->data[i] = (int8_t)v;
    }
}

void op_dequantize_q8(const QuantizedVec *in, float *out) {
    for (int i = 0; i < in->n; i++)
        out[i] = (float)in->data[i] * in->scale;
}

void op_matmul_q8(const QuantizedVec *in, const int8_t *wq8,
                  const float *ws, float *out, int in_dim, int out_dim) {
    for (int o = 0; o < out_dim; o++) {
        int32_t acc = 0;
        for (int i = 0; i < in_dim; i++)
            acc += (int32_t)in->data[i] * (int32_t)wq8[i * out_dim + o];
        out[o] = (float)acc * in->scale * ws[o];
    }
}
