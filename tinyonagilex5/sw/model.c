#include "model.h"
#include "ops.h"
#include <string.h>
#include <math.h>

// 初始化测试权重
void model_init(Model *m) {
    memset(m, 0, sizeof(Model));

    ModelWeights *w = &m->weights;

    // 词嵌入
    for (int i = 0; i < VOCAB_SIZE; i++)
        for (int j = 0; j < DIM; j++)
            w->token_embd[i][j] = 0.02f * (float)((i*7 + j*13) % 19 - 9) / 9.0f;

    // 层权重
    for (int l = 0; l < N_LAYERS; l++) {
        for (int i = 0; i < DIM; i++) {
            w->layers[l].attn_norm[i] = 1.0f;
            w->layers[l].ffn_norm[i]  = 1.0f;
            // Q/K/V/O = 单位矩阵
            w->layers[l].q_w[i][i] = 1.0f;
            w->layers[l].k_w[i][i] = 1.0f;
            w->layers[l].v_w[i][i] = 1.0f;
            w->layers[l].o_w[i][i] = 1.0f;
        }
        for (int i = 0; i < DIM; i++)
            for (int j = 0; j < FFN_DIM; j++) {
                w->layers[l].ffn_gate[i][j] = 0.01f * (float)((i+j) % 7 - 3) / 3.0f;
                w->layers[l].ffn_up[i][j]   = 0.01f * (float)((i*3+j) % 11 - 5) / 5.0f;
            }
        for (int i = 0; i < FFN_DIM; i++)
            for (int j = 0; j < DIM; j++)
                w->layers[l].ffn_down[i][j] = 0.01f * (float)((i+j*2) % 13 - 6) / 6.0f;
    }

    // 输出层
    for (int i = 0; i < DIM; i++)
        w->output_norm[i] = 1.0f;
    for (int i = 0; i < VOCAB_SIZE; i++)
        for (int j = 0; j < DIM; j++)
            w->output[i][j] = 0.02f * (float)((i*5 + j) % 23 - 11) / 11.0f;
}

// ============================================
// 完整推理流程（带 KV Cache）
// ============================================
//
// 数据流图:
//
//   token
//     │
//     ▼
//   [Embedding Lookup]         ← 查表，非计算
//     │
//     ▼ x[DIM]
//   ┌─────────────────────────────────────────┐
//   │ Transformer Block (重复 N_LAYERS 次)      │
//   │                                           │
//   │   x ──► [RMSNorm] ──► x_norm             │
//   │           │                               │
//   │           ▼                               │
//   │   x_norm ─┬── [MatMul Wq] ──► q          │  ← FPGA 加速
//   │           ├── [MatMul Wk] ──► k          │  ← FPGA 加速
//   │           └── [MatMul Wv] ──► v          │  ← FPGA 加速
//   │                │                          │
//   │                ▼                          │
//   │         [RoPE](q, k, pos)                │
//   │                │                          │
//   │                ▼                          │
//   │   k,v ──► [KV Cache 存储]                 │
//   │                │                          │
//   │                ▼                          │
//   │   q ──► [Attention Scores] ◄── k_cache   │  ← FPGA 加速
//   │                │                          │
//   │                ▼                          │
//   │         [Softmax]                        │
//   │                │                          │
//   │                ▼                          │
//   │         [Attention Mix] ◄── v_cache      │  ← FPGA 加速
//   │                │                          │
//   │                ▼                          │
//   │         [MatMul Wo] ──► attn_out         │  ← FPGA 加速
//   │                │                          │
//   │                ▼                          │
//   │   x = x + attn_out    (残差连接)          │
//   │                │                          │
//   │                ▼                          │
//   │   x ──► [RMSNorm] ──► x_norm             │
//   │           │                               │
//   │           ▼                               │
//   │   x_norm ─┬── [MatMul W_gate] ──► gate   │  ← FPGA 加速
//   │           └── [MatMul W_up]   ──► up     │  ← FPGA 加速
//   │                │                          │
//   │                ▼                          │
//   │         [SiLU](gate)                     │
//   │         gate = gate ⊙ up  (SwiGLU)      │
//   │                │                          │
//   │                ▼                          │
//   │         [MatMul W_down] ──► ffn_out      │  ← FPGA 加速
//   │                │                          │
//   │                ▼                          │
//   │   x = x + ffn_out    (残差连接)           │
//   │                                           │
//   └───────────────────────────────────────────┘
//     │
//     ▼
//   [RMSNorm]
//     │
//     ▼
//   [MatMul W_output] ──► logits[VOCAB_SIZE]     ← FPGA 加速
//     │
//     ▼
//   [Argmax] ──► next_token
//

int model_forward(Model *m, int token, int pos) {
    ModelWeights *w = &m->weights;
    KVCache *kv = &m->kv_cache;

    float x[DIM];
    float x_norm[DIM];
    float q[DIM], k[DIM], v[DIM];
    float attn_out[DIM];
    float scores[CTX_LEN];
    float gate_buf[FFN_DIM], up_buf[FFN_DIM];
    float tmp[DIM];

    // ---- Step 1: 词嵌入查表 ----
    memcpy(x, w->token_embd[token], sizeof(float) * DIM);

    // ---- Step 2~: 每层 Transformer ----
    for (int l = 0; l < N_LAYERS; l++) {

        // -- 2a. Attention 前的 RMSNorm --
        op_rmsnorm(x, w->layers[l].attn_norm, x_norm, DIM, 1e-5f);

        // -- 2b. 计算 Q, K, V --
        op_matmul(x_norm, (float*)w->layers[l].q_w, q, DIM, DIM);
        op_matmul(x_norm, (float*)w->layers[l].k_w, k, DIM, DIM);
        op_matmul(x_norm, (float*)w->layers[l].v_w, v, DIM, DIM);

        // -- 2c. RoPE 旋转位置编码 --
        op_rope(q, k, DIM, pos);

        // -- 2d. 存入 KV Cache --
        memcpy(kv->k[pos], k, sizeof(float) * DIM);
        memcpy(kv->v[pos], v, sizeof(float) * DIM);
        int seq_len = pos + 1;

        // -- 2e. 注意力分数 --
        op_attention_scores(q, (float*)kv->k, scores, DIM, seq_len);

        // -- 2f. Softmax --
        op_softmax(scores, seq_len);

        // -- 2g. 加权混合 V --
        op_attention_mix(scores, (float*)kv->v, attn_out, DIM, seq_len);

        // -- 2h. 输出投影 --
        op_matmul(attn_out, (float*)w->layers[l].o_w, tmp, DIM, DIM);

        // -- 2i. 残差连接 --
        op_vec_add(x, tmp, x, DIM);

        // -- 3a. FFN 前的 RMSNorm --
        op_rmsnorm(x, w->layers[l].ffn_norm, x_norm, DIM, 1e-5f);

        // -- 3b. SwiGLU FFN --
        op_matmul(x_norm, (float*)w->layers[l].ffn_gate, gate_buf, DIM, FFN_DIM);
        op_matmul(x_norm, (float*)w->layers[l].ffn_up,   up_buf,   DIM, FFN_DIM);

        op_silu(gate_buf, FFN_DIM);
        op_elem_mul(gate_buf, up_buf, gate_buf, FFN_DIM);

        op_matmul(gate_buf, (float*)w->layers[l].ffn_down, tmp, FFN_DIM, DIM);

        // -- 3c. 残差连接 --
        op_vec_add(x, tmp, x, DIM);
    }

    // ---- Step 4: 最终 RMSNorm ----
    op_rmsnorm(x, w->output_norm, x_norm, DIM, 1e-5f);

    // ---- Step 5: 输出层 ----
    float logits[VOCAB_SIZE];
    op_matmul(x_norm, (float*)w->output, logits, DIM, VOCAB_SIZE);

    // ---- Step 6: 选择 token ----
    return op_argmax(logits, VOCAB_SIZE);
}
