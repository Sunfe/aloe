#ifndef OPS_H
#define OPS_H

#include <stdint.h>

// ============================================
// 基础算子接口
//
// 设计原则:
// 1. 每个算子函数签名清晰，输入/输出分离
// 2. 没有动态内存分配
// 3. 纯计算，无副作用（适合硬件加速）
// 4. 每个函数都可以单独替换为 FPGA 版本
//
// FPGA 移植优先级 (从高到低):
//   ★★★ matmul         — 计算量最大，加速收益最高
//   ★★★ attention_dot  — 核心操作
//   ★★  softmax        — 有 exp/sum，适合流水线
//   ★★  rmsnorm        — 有 sqrt，适合流水线
//   ★★  silu / elem_mul— 简单，适合入门
//   ★   rope           — 有 sin/cos，中等难度
//   ★   vec_add        — 最简单
//   ★   argmax         — 最简单
// ============================================

// ---------- 1. 矩阵乘法 ----------
// out[out_dim] = in[in_dim] × W[in_dim][out_dim]
//
// FPGA 要点:
//   - 这是 LLM 推理中 90%+ 的计算量
//   - 用脉动阵列 (systolic array) 实现
//   - 关键: 权重预加载到 BRAM，输入流式送入
//   - 建议先做 定点化 (fixed-point) 版本
void op_matmul(const float *in, const float *weight,
               float *out, int in_dim, int out_dim);

// ---------- 2. 向量加法 (残差连接) ----------
// out[n] = a[n] + b[n]
//
// FPGA 要点:
//   - 最简单的算子，适合 FPGA 入门
//   - 每周期处理一个/多个元素
//   - 可以和 matmul 输出级联 (fused)
void op_vec_add(const float *a, const float *b,
                float *out, int n);

// ---------- 3. 逐元素乘法 ----------
// out[n] = a[n] * b[n]
//
// FPGA 要点:
//   - SwiGLU 中用到: gate * up
//   - 和 vec_add 一样简单
void op_elem_mul(const float *a, const float *b,
                 float *out, int n);

// ---------- 4. RMS Norm ----------
// out[i] = (x[i] / rms(x)) * weight[i]
// rms(x) = sqrt(mean(x^2) + eps)
//
// FPGA 要点:
//   - 需要两遍扫描: 第一遍算平方和，第二遍归一化
//   - sqrt 用查表 (LUT) 或牛顿迭代
//   - 可用定点数，精度要求不高
void op_rmsnorm(const float *x, const float *weight,
                float *out, int dim, float eps);

// ---------- 5. RoPE 旋转位置编码 ----------
// 对 Q/K 向量施加位置信息
// 每两个相邻元素做 2D 旋转
//
// FPGA 要点:
//   - sin/cos 用 CORDIC 算法或查表
//   - 预计算 sin/cos 表存入 BRAM
//   - 每周期处理一对元素
void op_rope(float *q, float *k, int dim, int pos);

// ---------- 6. Softmax ----------
// out[i] = exp(x[i] - max) / sum(exp(x[j] - max))
//
// FPGA 要点:
//   - 三遍扫描: 找max -> 算exp求和 -> 归一化
//   - exp 用分段线性近似或查表
//   - 注意力矩阵维度 = seq_len，通常不大
void op_softmax(float *x, int n);

// ---------- 7. SiLU 激活函数 ----------
// out[i] = x[i] * sigmoid(x[i])
// sigmoid(x) = 1 / (1 + exp(-x))
//
// FPGA 要点:
//   - LLaMA 用 SiLU 而不是 ReLU
//   - sigmoid 用分段线性近似或查表
//   - 可以和 elem_mul 融合
void op_silu(float *x, int n);

// ---------- 8. ReLU 激活函数 ----------
// out[i] = max(0, x[i])
//
// FPGA 要点:
//   - 最简单的非线性，1个比较器
//   - 用于早期测试
void op_relu(float *x, int n);

// ---------- 9. Argmax ----------
// return index of max element
//
// FPGA 要点:
//   - 树形比较器，O(log n) 级联
//   - 用于最终 token 选择
int op_argmax(const float *x, int n);

// ---------- 10. 注意力点积 ----------
// scores[t] = sum(q[i] * k[t][i]) / sqrt(dim)  for t=0..pos
//
// FPGA 要点:
//   - 本质上是多次向量点积
//   - Q 固定，K 从 KV cache 顺序读出
//   - 可以流水线化
void op_attention_scores(const float *q, const float *k_cache,
                         float *scores, int dim, int seq_len);

// ---------- 11. 加权求和 ----------
// out[i] = sum(weights[t] * v[t][i])  for t=0..seq_len
//
// FPGA 要点:
//   - weights 来自 softmax 输出
//   - V 从 KV cache 顺序读出
//   - MAC 累加器阵列
void op_attention_mix(const float *weights, const float *v_cache,
                      float *out, int dim, int seq_len);

// ---------- 12. 定点数转换 (FPGA 专用) ----------
// float32 <-> Q8 (8位定点数)
// 用于 FPGA 加速时的数据格式转换
//
// FPGA 要点:
//   - float32 在 FPGA 上很贵 (DSP 占用多)
//   - Q8/Q16 定点数大幅节省资源
//   - 量化公式: q = round(x / scale)
//   - 反量化: x = q * scale

typedef struct {
    int8_t *data;
    float   scale;
    int     n;
} QuantizedVec;

void op_quantize_q8(const float *in, QuantizedVec *out, int n);
void op_dequantize_q8(const QuantizedVec *in, float *out);
// 定点矩阵乘 (FPGA 主力算子)
void op_matmul_q8(const QuantizedVec *in, const int8_t *weight_q8,
                  const float *weight_scales, float *out,
                  int in_dim, int out_dim);

#endif
