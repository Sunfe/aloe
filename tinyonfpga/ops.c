#include "ops.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

// ============================================
// 每个算子都有详细注释，说明:
//   1. 数学原理
//   2. 计算复杂度
//   3. FPGA 实现建议
// ============================================

// -------------------------------------------
// 1. 矩阵乘法 (Matrix-Vector Multiply)
// -------------------------------------------
// 数学: out[j] = Σ_i (in[i] * W[i][j])
// 复杂度: O(in_dim * out_dim) 乘加
//
// FPGA 实现方案:
//   方案A: 脉动阵列 (Systolic Array)
//     - 权重预加载到 PE 阵列
//     - 输入数据从左侧流入
//     - 结果从底部流出
//     - 适合大矩阵
//
//   方案B: 向量 MAC 单元
//     - 每周期读一行权重
//     - 和输入向量做点积
//     - 适合小模型 (我们的情况)
//
//   资源估算 (DIM=64):
//     - 64个并行乘法器 + 加法树
//     - 约 64 DSP48 单元
//     - Xilinx Artix-7 有 240 个 DSP48，足够
//
void op_matmul(const float *in, const float *weight,
               float *out, int in_dim, int out_dim) {
    for (int o = 0; o < out_dim; o++) {
        float sum = 0.0f;
        // 内层循环 = 一次向量点积
        // FPGA: 这个循环展开为并行乘加
        for (int i = 0; i < in_dim; i++) {
            sum += in[i] * weight[i * out_dim + o];
        }
        out[o] = sum;
    }
}

// -------------------------------------------
// 2. 向量加法 (残差连接)
// -------------------------------------------
// 数学: out[i] = a[i] + b[i]
// 复杂度: O(n)
//
// FPGA: 最简单，N个并行加法器
//       可以和 matmul 输出融合
//
void op_vec_add(const float *a, const float *b,
                float *out, int n) {
    for (int i = 0; i < n; i++) {
        out[i] = a[i] + b[i];
    }
}

// -------------------------------------------
// 3. 逐元素乘法
// -------------------------------------------
// 数学: out[i] = a[i] * b[i]
// 复杂度: O(n)
//
// FPGA: N个并行乘法器，1 DSP48 each
//
void op_elem_mul(const float *a, const float *b,
                 float *out, int n) {
    for (int i = 0; i < n; i++) {
        out[i] = a[i] * b[i];
    }
}

// -------------------------------------------
// 4. RMS Normalization
// -------------------------------------------
// 数学:
//   rms = sqrt( (1/n) * Σ x[i]^2 + eps )
//   out[i] = (x[i] / rms) * weight[i]
//
// 复杂度: O(2n) —— 两遍扫描
//
// FPGA 实现:
//   Pass 1: 累加 x[i]^2 (流水线 MAC)
//   中间:   计算 1/sqrt(sum/n + eps)
//           用牛顿迭代: y = y * (1.5 - 0.5*x*y*y)
//           或查表 + 一次迭代
//   Pass 2: out[i] = x[i] * inv_rms * weight[i]
//           (两次乘法，可流水线)
//
void op_rmsnorm(const float *x, const float *weight,
                float *out, int dim, float eps) {
    // Pass 1: 计算平方和
    float sum_sq = 0.0f;
    for (int i = 0; i < dim; i++) {
        sum_sq += x[i] * x[i];
    }

    // 计算 1/rms
    float inv_rms = 1.0f / sqrtf(sum_sq / (float)dim + eps);

    // Pass 2: 归一化并缩放
    for (int i = 0; i < dim; i++) {
        out[i] = x[i] * inv_rms * weight[i];
    }
}

// -------------------------------------------
// 5. RoPE 旋转位置编码
// -------------------------------------------
// 数学: 对于第 i 对元素 (x[2i], x[2i+1]):
//   freq = 1.0 / (10000^(2i/dim))
//   θ    = pos * freq
//   x[2i]   = x[2i]*cos(θ)   - x[2i+1]*sin(θ)
//   x[2i+1] = x[2i]*sin(θ)   + x[2i+1]*cos(θ)
//
// 复杂度: O(dim) 乘加 + sin/cos 计算
//
// FPGA 实现:
//   - 预计算 freq 表存入 ROM (dim/2 个值)
//   - sin/cos 用 CORDIC IP 核
//     Xilinx: 直接用 CORDIC IP
//     或者预计算 sin/cos 查找表 (CTX_LEN * dim/2)
//     128 * 32 = 4096 对 sin/cos = 32KB，可放 BRAM
//   - 每周期处理一对元素
//   - 2 个乘法器 + 1 个加/减法器
//
void op_rope(float *q, float *k, int dim, int pos) {
    for (int i = 0; i < dim / 2; i++) {
        // 频率: 越高维衰减越快
        float freq = 1.0f / powf(10000.0f, (float)(2 * i) / (float)dim);
        float theta = (float)pos * freq;
        float cos_t = cosf(theta);
        float sin_t = sinf(theta);

        // 旋转 Q
        float q0 = q[2*i], q1 = q[2*i+1];
        q[2*i]   = q0 * cos_t - q1 * sin_t;
        q[2*i+1] = q0 * sin_t + q1 * cos_t;

        // 旋转 K
        float k0 = k[2*i], k1 = k[2*i+1];
        k[2*i]   = k0 * cos_t - k1 * sin_t;
        k[2*i+1] = k0 * sin_t + k1 * cos_t;
    }
}

// -------------------------------------------
// 6. Softmax
// -------------------------------------------
// 数学:
//   m = max(x[i])
//   out[i] = exp(x[i] - m) / Σ exp(x[j] - m)
//
// 复杂度: O(3n) —— 三遍扫描
//
// FPGA 实现:
//   Pass 1: 找 max (树形比较器, O(log n) 延迟)
//   Pass 2: 计算 exp(x[i]-max) 并累加
//           exp 近似方法:
//           a) 分段线性近似 (精度 ~1%)
//           b) 查表 + 线性插值
//           c) 利用 2^x 硬件: exp(x) = 2^(x/ln2)
//   Pass 3: 除法归一化
//           用牛顿迭代求倒数，避免硬除法
//
void op_softmax(float *x, int n) {
    // Pass 1: 找最大值 (数值稳定性)
    float max_val = x[0];
    for (int i = 1; i < n; i++) {
        if (x[i] > max_val) max_val = x[i];
    }

    // Pass 2: exp 并求和
    float sum = 0.0f;
    for (int i = 0; i < n; i++) {
        x[i] = expf(x[i] - max_val);
        sum += x[i];
    }

    // Pass 3: 归一化
    float inv_sum = 1.0f / sum;
    for (int i = 0; i < n; i++) {
        x[i] *= inv_sum;
    }
}

// -------------------------------------------
// 7. SiLU 激活函数 (Swish)
// -------------------------------------------
// 数学: silu(x) = x * σ(x) = x / (1 + exp(-x))
//
// FPGA 实现:
//   方案A: 查表
//     - 对 x ∈ [-8, 8] 建 256 项查找表
//     - 超出范围: x<-8 返回 0, x>8 返回 x
//     - 占用 1 BRAM18K
//
//   方案B: 分段线性近似
//     x < -5:    silu ≈ 0
//     -5 < x < 5: silu ≈ 查表 + 线性插值
//     x > 5:     silu ≈ x
//
void op_silu(float *x, int n) {
    for (int i = 0; i < n; i++) {
        float val = x[i];
        float sigmoid = 1.0f / (1.0f + expf(-val));
        x[i] = val * sigmoid;
    }
}

// -------------------------------------------
// 8. ReLU 激活函数
// -------------------------------------------
// 数学: relu(x) = max(0, x)
//
// FPGA: 1 个比较器 + 1 个 MUX
//       最简单的非线性，适合入门测试
//
void op_relu(float *x, int n) {
    for (int i = 0; i < n; i++) {
        if (x[i] < 0.0f) x[i] = 0.0f;
    }
}

// -------------------------------------------
// 9. Argmax
// -------------------------------------------
// 找最大值的索引
//
// FPGA: 树形比较网络
//   64 个元素 -> 6 级比较 -> 6 个时钟周期
//   每级: 并行比较，保留较大值及其索引
//
int op_argmax(const float *x, int n) {
    int best = 0;
    for (int i = 1; i < n; i++) {
        if (x[i] > x[best]) best = i;
    }
    return best;
}

// -------------------------------------------
// 10. 注意力分数计算
// -------------------------------------------
// 数学: scores[t] = (q · k_t) / √dim
//
// FPGA: 对每个时间步 t:
//   - 从 KV cache BRAM 读出 k[t]
//   - 和 q 做向量点积 (64个并行MAC)
//   - 乘以 scale (预计算的常数)
//   - 吞吐量: 每周期算1个score (全并行)
//             或每 dim 周期算1个 (串行)
//
void op_attention_scores(const float *q, const float *k_cache,
                         float *scores, int dim, int seq_len) {
    float scale = 1.0f / sqrtf((float)dim);
    for (int t = 0; t < seq_len; t++) {
        float dot = 0.0f;
        const float *kt = k_cache + t * dim;
        for (int i = 0; i < dim; i++) {
            dot += q[i] * kt[i];
        }
        scores[t] = dot * scale;
    }
}

// -------------------------------------------
// 11. 注意力加权混合
// -------------------------------------------
// 数学: out[i] = Σ_t weights[t] * v[t][i]
//
// FPGA: 对每个维度 i:
//   - 累加 weights[t] * v_cache[t][i]
//   - 可以转置存储 v_cache，让同一维度连续
//   - 或者用 dim 个并行累加器
//
void op_attention_mix(const float *weights, const float *v_cache,
                      float *out, int dim, int seq_len) {
    memset(out, 0, sizeof(float) * dim);
    for (int t = 0; t < seq_len; t++) {
        const float *vt = v_cache + t * dim;
        float w = weights[t];
        for (int i = 0; i < dim; i++) {
            out[i] += w * vt[i];
        }
    }
}

// -------------------------------------------
// 12. 定点量化 (Q8)
// -------------------------------------------
// 数学:
//   scale = max(|x|) / 127
//   q[i] = round(x[i] / scale)    , clamp to [-128, 127]
//
// FPGA 要点:
//   - 权重离线量化，推理时只需反量化
//   - 输入在线量化: 找max -> 算scale -> 量化
//   - Q8 矩阵乘: 用 8-bit 乘法器
//     1 个 DSP48 可以做 2 个 8-bit 乘法
//     资源减半！
//
void op_quantize_q8(const float *in, QuantizedVec *out, int n) {
    // 找绝对值最大值
    float amax = 0.0f;
    for (int i = 0; i < n; i++) {
        float a = fabsf(in[i]);
        if (a > amax) amax = a;
    }

    float scale = amax / 127.0f;
    if (scale == 0.0f) scale = 1.0f;

    out->scale = scale;
    out->n = n;
    if (out->data == NULL) {
        out->data = (int8_t*)malloc(n);
    }

    float inv_scale = 1.0f / scale;
    for (int i = 0; i < n; i++) {
        int v = (int)roundf(in[i] * inv_scale);
        if (v > 127) v = 127;
        if (v < -128) v = -128;
        out->data[i] = (int8_t)v;
    }
}

void op_dequantize_q8(const QuantizedVec *in, float *out) {
    for (int i = 0; i < in->n; i++) {
        out[i] = (float)in->data[i] * in->scale;
    }
}

// Q8 矩阵乘: int8 权重 × int8 输入 -> float32 输出
// FPGA 核心算子！
void op_matmul_q8(const QuantizedVec *in, const int8_t *weight_q8,
                  const float *weight_scales, float *out,
                  int in_dim, int out_dim) {
    for (int o = 0; o < out_dim; o++) {
        int32_t acc = 0;  // 用 int32 累加，避免溢出
        // FPGA: 这个循环 = 一个 MAC 阵列
        for (int i = 0; i < in_dim; i++) {
            acc += (int32_t)in->data[i] * (int32_t)weight_q8[i * out_dim + o];
        }
        // 反量化: float = int32_acc * input_scale * weight_scale
        out[o] = (float)acc * in->scale * weight_scales[o];
    }
}
