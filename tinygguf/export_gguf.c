#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include "tiny_llm_gguf.h"

// ========== GGUF 常量 ==========
#define GGUF_VERSION 3

enum gguf_type {
    GGUF_TYPE_UINT8   = 0,
    GGUF_TYPE_INT8    = 1,
    GGUF_TYPE_UINT16  = 2,
    GGUF_TYPE_INT16   = 3,
    GGUF_TYPE_UINT32  = 4,
    GGUF_TYPE_INT32   = 5,
    GGUF_TYPE_FLOAT32 = 6,
    GGUF_TYPE_BOOL    = 7,
    GGUF_TYPE_STRING  = 8,
    GGUF_TYPE_ARRAY   = 9,
    GGUF_TYPE_UINT64  = 10,
    GGUF_TYPE_INT64   = 11,
    GGUF_TYPE_FLOAT64 = 12,
};

#define GGML_TYPE_F32 0

// ========== 写入辅助函数 ==========
static void write_magic(FILE *f) {
    const char magic[4] = {'G', 'G', 'U', 'F'};
    fwrite(magic, 1, 4, f);
}
static void wr_u32(FILE *f, uint32_t v) { fwrite(&v, 4, 1, f); }
static void wr_u64(FILE *f, uint64_t v) { fwrite(&v, 8, 1, f); }
static void wr_i32(FILE *f, int32_t v)  { fwrite(&v, 4, 1, f); }
static void wr_f32(FILE *f, float v)    { fwrite(&v, 4, 1, f); }
static void wr_u8 (FILE *f, uint8_t v)  { fwrite(&v, 1, 1, f); }

static void wr_str(FILE *f, const char *s) {
    uint64_t len = (uint64_t)strlen(s);
    wr_u64(f, len);
    fwrite(s, 1, (size_t)len, f);
}

// KV 写入
static void kv_str(FILE *f, const char *key, const char *val) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_STRING);
    wr_str(f, val);
}
static void kv_u32(FILE *f, const char *key, uint32_t val) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_UINT32);
    wr_u32(f, val);
}
static void kv_f32(FILE *f, const char *key, float val) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_FLOAT32);
    wr_f32(f, val);
}

// 写 string array
static void kv_str_array(FILE *f, const char *key,
                         const char **arr, uint64_t count) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_ARRAY);
    wr_u32(f, GGUF_TYPE_STRING);
    wr_u64(f, count);
    for (uint64_t i = 0; i < count; i++) {
        wr_str(f, arr[i]);
    }
}

// 写 float32 array
static void kv_f32_array(FILE *f, const char *key,
                         const float *arr, uint64_t count) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_ARRAY);
    wr_u32(f, GGUF_TYPE_FLOAT32);
    wr_u64(f, count);
    for (uint64_t i = 0; i < count; i++) {
        wr_f32(f, arr[i]);
    }
}

// 写 int32 array
static void kv_i32_array(FILE *f, const char *key,
                         const int32_t *arr, uint64_t count) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_ARRAY);
    wr_u32(f, GGUF_TYPE_INT32);
    wr_u64(f, count);
    for (uint64_t i = 0; i < count; i++) {
        wr_i32(f, arr[i]);
    }
}

// 张量信息
static uint64_t write_tensor_info(FILE *f, const char *name,
                                  int n_dims, uint64_t *dims,
                                  uint32_t type, uint64_t offset) {
    wr_str(f, name);
    wr_u32(f, (uint32_t)n_dims);
    for (int i = 0; i < n_dims; i++) {
        wr_u64(f, dims[i]);
    }
    wr_u32(f, type);
    wr_u64(f, offset);

    uint64_t n_elem = 1;
    for (int i = 0; i < n_dims; i++) n_elem *= dims[i];
    return n_elem * sizeof(float);
}

// 对齐
static void pad_to(FILE *f, int alignment) {
    long pos = ftell(f);
    long pad = (alignment - (pos % alignment)) % alignment;
    for (long i = 0; i < pad; i++) wr_u8(f, 0);
}

// ========== 权重 ==========
static float token_embd[VOCAB_SIZE][DIM];
static float attn_norm_w[DIM];
static float attn_q_w[DIM][DIM];
static float attn_k_w[DIM][DIM];
static float attn_v_w[DIM][DIM];
static float attn_out_w[DIM][DIM];
static float ffn_norm_w[DIM];
static float ffn_gate_w[DIM][FFN_DIM];
static float ffn_up_w[DIM][FFN_DIM];
static float ffn_down_w[FFN_DIM][DIM];
static float output_norm_w[DIM];
static float output_w[VOCAB_SIZE][DIM];

static void init_weights(void) {
    for (int i = 0; i < VOCAB_SIZE; i++) {
        for (int j = 0; j < DIM; j++) {
            token_embd[i][j] = 0.02f * (float)((i * 7 + j * 13) % 19 - 9) / 9.0f;
            output_w[i][j]   = 0.02f * (float)((i * 5 + j) % 23 - 11) / 11.0f;
        }
    }

    for (int i = 0; i < DIM; i++) {
        attn_norm_w[i]   = 1.0f;
        ffn_norm_w[i]    = 1.0f;
        output_norm_w[i] = 1.0f;
    }

    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            float v = (i == j) ? 1.0f : 0.0f;
            attn_q_w[i][j]   = v;
            attn_k_w[i][j]   = v;
            attn_v_w[i][j]   = v;
            attn_out_w[i][j] = v;
        }
    }

    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < FFN_DIM; j++) {
            ffn_gate_w[i][j] = 0.01f * (float)((i + j) % 7 - 3) / 3.0f;
            ffn_up_w[i][j]   = 0.01f * (float)((i * 3 + j) % 11 - 5) / 5.0f;
        }
    }

    for (int i = 0; i < FFN_DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            ffn_down_w[i][j] = 0.01f * (float)((i + j * 2) % 13 - 6) / 6.0f;
        }
    }
}

// ========== Tokenizer ==========
static const char *vocab_tokens[VOCAB_SIZE];
static int32_t     vocab_types[VOCAB_SIZE];
static float       vocab_scores[VOCAB_SIZE];
static char        token_buf[VOCAB_SIZE][32];

static void build_tokenizer(void) {
    // special tokens
    strcpy(token_buf[0], "<unk>");  vocab_types[0] = 2; vocab_scores[0] = 0.0f;
    strcpy(token_buf[1], "<s>");    vocab_types[1] = 3; vocab_scores[1] = 0.0f;
    strcpy(token_buf[2], "</s>");   vocab_types[2] = 3; vocab_scores[2] = 0.0f;

    // simple normal tokens
    for (int i = 3; i < VOCAB_SIZE; i++) {
        snprintf(token_buf[i], sizeof(token_buf[i]), "token_%d", i);
        vocab_types[i] = 1;   // normal token
        vocab_scores[i] = -1.0f;
    }

    for (int i = 0; i < VOCAB_SIZE; i++) {
        vocab_tokens[i] = token_buf[i];
    }
}

int main(void) {
    init_weights();
    build_tokenizer();

    FILE *f = fopen("tiny_llama.gguf", "wb");
    if (!f) {
        perror("fopen");
        return 1;
    }

    // ---- Header ----
    write_magic(f);
    wr_u32(f, GGUF_VERSION);

    uint64_t n_tensors = 12;
    wr_u64(f, n_tensors);

    // KV 数量
    uint64_t n_kv = 19;
    wr_u64(f, n_kv);

    // ---- 模型元数据 ----
    kv_str(f, "general.architecture", "llama");
    kv_str(f, "general.name", "tiny-llama-learning");
    kv_u32(f, "general.file_type", 0);

    kv_u32(f, "llama.context_length", CTX_LEN);
    kv_u32(f, "llama.embedding_length", DIM);
    kv_u32(f, "llama.block_count", N_LAYERS);
    kv_u32(f, "llama.feed_forward_length", FFN_DIM);
    kv_u32(f, "llama.attention.head_count", N_HEADS);
    kv_u32(f, "llama.attention.head_count_kv", N_KV_HEADS);
    kv_u32(f, "llama.rope.dimension_count", ROPE_DIM);
    kv_f32(f, "llama.attention.layer_norm_rms_epsilon", 1e-5f);

    // tokenizer
    kv_str(f, "tokenizer.ggml.model", "llama");
    kv_str(f, "tokenizer.chat_template", "{{prompt}}");

    kv_str_array(f, "tokenizer.ggml.tokens", vocab_tokens, VOCAB_SIZE);
    kv_f32_array(f, "tokenizer.ggml.scores", vocab_scores, VOCAB_SIZE);
    kv_i32_array(f, "tokenizer.ggml.token_type", vocab_types, VOCAB_SIZE);

    kv_u32(f, "tokenizer.ggml.bos_token_id", 1);
    kv_u32(f, "tokenizer.ggml.eos_token_id", 2);
    kv_u32(f, "tokenizer.ggml.unknown_token_id", 0);

    // ---- 张量信息 ----
    uint64_t offset = 0;
    int ti = 0;

    #define T2D(name, d0, d1) do { \
        uint64_t d[] = { (uint64_t)(d0), (uint64_t)(d1) }; \
        write_tensor_info(f, name, 2, d, GGML_TYPE_F32, offset); \
        offset += (uint64_t)(d0) * (uint64_t)(d1) * sizeof(float); \
        ti++; \
    } while (0)

    #define T1D(name, d0) do { \
        uint64_t d[] = { (uint64_t)(d0) }; \
        write_tensor_info(f, name, 1, d, GGML_TYPE_F32, offset); \
        offset += (uint64_t)(d0) * sizeof(float); \
        ti++; \
    } while (0)

    T2D("token_embd.weight",        DIM, VOCAB_SIZE);
    T1D("blk.0.attn_norm.weight",   DIM);
    T2D("blk.0.attn_q.weight",      DIM, DIM);
    T2D("blk.0.attn_k.weight",      DIM, DIM);
    T2D("blk.0.attn_v.weight",      DIM, DIM);
    T2D("blk.0.attn_output.weight", DIM, DIM);
    T1D("blk.0.ffn_norm.weight",    DIM);
    T2D("blk.0.ffn_gate.weight",    DIM, FFN_DIM);
    T2D("blk.0.ffn_up.weight",      DIM, FFN_DIM);
    T2D("blk.0.ffn_down.weight",    FFN_DIM, DIM);
    T1D("output_norm.weight",       DIM);
    T2D("output.weight",            DIM, VOCAB_SIZE);

    // ---- 对齐 + 写张量数据 ----
    pad_to(f, 32);

    fwrite(token_embd,     sizeof(float), VOCAB_SIZE * DIM, f);
    fwrite(attn_norm_w,    sizeof(float), DIM, f);
    fwrite(attn_q_w,       sizeof(float), DIM * DIM, f);
    fwrite(attn_k_w,       sizeof(float), DIM * DIM, f);
    fwrite(attn_v_w,       sizeof(float), DIM * DIM, f);
    fwrite(attn_out_w,     sizeof(float), DIM * DIM, f);
    fwrite(ffn_norm_w,     sizeof(float), DIM, f);
    fwrite(ffn_gate_w,     sizeof(float), DIM * FFN_DIM, f);
    fwrite(ffn_up_w,       sizeof(float), DIM * FFN_DIM, f);
    fwrite(ffn_down_w,     sizeof(float), FFN_DIM * DIM, f);
    fwrite(output_norm_w,  sizeof(float), DIM, f);
    fwrite(output_w,       sizeof(float), VOCAB_SIZE * DIM, f);

    long file_size = ftell(f);
    fclose(f);

    printf("=== GGUF 导出完成 ===\n");
    printf("文件: tiny_llama.gguf (%ld bytes, %.1f KB)\n",
           file_size, (float)file_size / 1024.0f);
    printf("张量: %d 个 (F32)\n", ti);
    printf("模型: %d层, dim=%d, heads=%d, ffn=%d, vocab=%d\n",
           N_LAYERS, DIM, N_HEADS, FFN_DIM, VOCAB_SIZE);
    printf("Tokenizer: llama, %d tokens\n", VOCAB_SIZE);
    printf("KV 元数据: %d 项\n", (int)n_kv);
    printf("测试命令:\n");
    printf("  ./build/bin/llama-cli -m tiny_llama.gguf -p \"hello\" -n 10\n");

    return 0;
}
