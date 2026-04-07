#ifndef MODEL_H
#define MODEL_H

#include "tiny_llm_gguf.h"

// KV Cache: 存储历史 K, V 向量
typedef struct {
    float k[CTX_LEN][DIM];  // [seq_pos][dim]
    float v[CTX_LEN][DIM];
    int   len;               // 当前缓存长度
} KVCache;

// 模型权重
typedef struct {
    // 词嵌入
    float token_embd[VOCAB_SIZE][DIM];

    // 每层的权重 (我们只有1层，但结构支持扩展)
    struct {
        float attn_norm[DIM];
        float q_w[DIM][DIM];
        float k_w[DIM][DIM];
        float v_w[DIM][DIM];
        float o_w[DIM][DIM];
        float ffn_norm[DIM];
        float ffn_gate[DIM][FFN_DIM];
        float ffn_up[DIM][FFN_DIM];
        float ffn_down[FFN_DIM][DIM];
    } layers[N_LAYERS];

    // 输出层
    float output_norm[DIM];
    float output[VOCAB_SIZE][DIM];
} ModelWeights;

// 推理上下文
typedef struct {
    ModelWeights weights;
    KVCache      kv_cache;
    int          use_fpga;  // 0=CPU, 1=FPGA 加速
} Model;

// 初始化模型 (填充测试权重)
void model_init(Model *m);

// 推理一个 token，返回下一个 token
int model_forward(Model *m, int token, int pos);

#endif
