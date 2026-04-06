// export_gguf_v2.c
// 导出一个符合 llama.cpp GGUF 读取逻辑的最小可用模型

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

#define VOCAB_SIZE  64
#define DIM         64
#define FFN_DIM     172
#define N_LAYERS    1
#define N_HEADS     4
#define N_KV_HEADS  4
#define HEAD_DIM    (DIM / N_HEADS)
#define ROPE_DIM    HEAD_DIM
#define CTX_LEN     128

#define GGUF_VERSION 3

enum gguf_value_type {
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

static void wr_u8(FILE *f, uint8_t v) { fwrite(&v, 1, 1, f); }
static void wr_u32(FILE *f, uint32_t v) { fwrite(&v, 4, 1, f); }
static void wr_u64(FILE *f, uint64_t v) { fwrite(&v, 8, 1, f); }
static void wr_i32(FILE *f, int32_t v)  { fwrite(&v, 4, 1, f); }
static void wr_f32(FILE *f, float v)    { fwrite(&v, 4, 1, f); }

static void write_magic(FILE *f) {
    const char magic[4] = {'G', 'G', 'U', 'F'};
    fwrite(magic, 1, 4, f);
}

static void wr_str(FILE *f, const char *s) {
    uint64_t len = (uint64_t)strlen(s);
    wr_u64(f, len);
    fwrite(s, 1, (size_t)len, f);
}

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

static void kv_bool(FILE *f, const char *key, uint8_t val) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_BOOL);
    wr_u8(f, val ? 1 : 0);
}

static void kv_str_array(FILE *f, const char *key, const char **arr, uint64_t count) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_ARRAY);
    wr_u32(f, GGUF_TYPE_STRING);
    wr_u64(f, count);
    for (uint64_t i = 0; i < count; i++) wr_str(f, arr[i]);
}

static void kv_f32_array(FILE *f, const char *key, const float *arr, uint64_t count) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_ARRAY);
    wr_u32(f, GGUF_TYPE_FLOAT32);
    wr_u64(f, count);
    for (uint64_t i = 0; i < count; i++) wr_f32(f, arr[i]);
}

static void kv_i32_array(FILE *f, const char *key, const int32_t *arr, uint64_t count) {
    wr_str(f, key);
    wr_u32(f, GGUF_TYPE_ARRAY);
    wr_u32(f, GGUF_TYPE_INT32);
    wr_u64(f, count);
    for (uint64_t i = 0; i < count; i++) wr_i32(f, arr[i]);
}

static uint64_t tensor_info_bytes(FILE *f, const char *name,
                                  int n_dims, const uint64_t *dims,
                                  uint32_t type, uint64_t offset) {
    wr_str(f, name);
    wr_u32(f, (uint32_t)n_dims);
    for (int i = 0; i < n_dims; i++) wr_u64(f, dims[i]);
    wr_u32(f, type);
    wr_u64(f, offset);

    uint64_t n_elem = 1;
    for (int i = 0; i < n_dims; i++) n_elem *= dims[i];
    return n_elem * sizeof(float);
}

static void pad_to(FILE *f, int alignment) {
    long pos = ftell(f);
    long pad = (alignment - (pos % alignment)) % alignment;
    for (long i = 0; i < pad; i++) wr_u8(f, 0);
}

// =====================
// weights
// =====================
static float token_embd[VOCAB_SIZE][DIM];
static float attn_norm_w[DIM];
static float attn_q_w[DIM][DIM];
static float attn_k_w[DIM][DIM];
static float attn_v_w[DIM][DIM];
static float attn_out_w[DIM][DIM];
static float ffn_norm_w[DIM];
static float ffn_gate_w[FFN_DIM][DIM];
static float ffn_up_w[FFN_DIM][DIM];
static float ffn_down_w[DIM][FFN_DIM];
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
        attn_norm_w[i] = 1.0f;
        ffn_norm_w[i] = 1.0f;
        output_norm_w[i] = 1.0f;
    }
    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            float v = (i == j) ? 1.0f : 0.0f;
            attn_q_w[i][j] = v;
            attn_k_w[i][j] = v;
            attn_v_w[i][j] = v;
            attn_out_w[i][j] = v;
        }
    }
    for (int i = 0; i < FFN_DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            ffn_gate_w[i][j] = 0.01f * (float)((i + j) % 7 - 3) / 3.0f;
            ffn_up_w[i][j]   = 0.01f * (float)((i * 3 + j) % 11 - 5) / 5.0f;
        }
    }
    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < FFN_DIM; j++) {
            ffn_down_w[i][j] = 0.01f * (float)((i + j * 2) % 13 - 6) / 6.0f;
        }
    }
}

// =====================
// tokenizer - BPE style with merges
// =====================
static const char *vocab_tokens[VOCAB_SIZE];
static int32_t vocab_types[VOCAB_SIZE];
static float vocab_scores[VOCAB_SIZE];
static char token_buf[VOCAB_SIZE][32];

// BPE merges
static const char *bpe_merges[] = {
    "t h",
    "h e",
    "i n",
    "e r",
    "a n",
    "r e",
    "o n",
    "a t",
    "e n",
    "n d",
    "t i",
    "e s",
    "o r",
    "t e",
    "o f",
    "e d",
    "i s",
    "i t",
    "a l",
    "a r",
    "s t",
    "t o",
    "n t",
    "n g",
    "s e",
    "h a",
    "a s",
    "o u",
};
static const int n_merges = 28;

static void build_tokenizer(void) {
    for (int i = 0; i < VOCAB_SIZE; i++) {
        token_buf[i][0] = '\0';
        vocab_tokens[i] = token_buf[i];
        vocab_types[i] = 1;
        vocab_scores[i] = -100.0f;
    }

    // Special tokens
    strcpy(token_buf[0], "<unk>"); vocab_types[0] = 2; vocab_scores[0] = 0.0f;
    strcpy(token_buf[1], "<s>");   vocab_types[1] = 3; vocab_scores[1] = 0.0f;
    strcpy(token_buf[2], "</s>");  vocab_types[2] = 3; vocab_scores[2] = 0.0f;
    strcpy(token_buf[3], "<pad>"); vocab_types[3] = 3; vocab_scores[3] = 0.0f;

    // Single ASCII characters: a-z
    for (int i = 0; i < 26; i++) {
        token_buf[4 + i][0] = (char)('a' + i);
        token_buf[4 + i][1] = '\0';
        vocab_types[4 + i] = 1;
        vocab_scores[4 + i] = -1.0f * (float)i;
    }

    // 0-3
    for (int i = 0; i < 4; i++) {
        token_buf[30 + i][0] = (char)('0' + i);
        token_buf[30 + i][1] = '\0';
        vocab_types[30 + i] = 1;
        vocab_scores[30 + i] = -30.0f;
    }

    // space, newline
    strcpy(token_buf[34], " ");
    vocab_types[34] = 1;
    vocab_scores[34] = -0.5f;

    strcpy(token_buf[35], "\n");
    vocab_types[35] = 1;
    vocab_scores[35] = -1.0f;

    // Bigram tokens
    const char *bigrams[] = {
        "th", "he", "in", "er", "an", "re", "on", "at",
        "en", "nd", "ti", "es", "or", "te", "of", "ed",
        "is", "it", "al", "ar", "st", "to", "nt", "ng",
        "se", "ha", "as", "ou"
    };
    for (int i = 0; i < 28 && (36 + i) < VOCAB_SIZE; i++) {
        strcpy(token_buf[36 + i], bigrams[i]);
        vocab_types[36 + i] = 1;
        vocab_scores[36 + i] = -40.0f - (float)i;
    }
}

int main(void) {
    init_weights();
    build_tokenizer();

    FILE *f = fopen("tiny_llama.gguf", "wb");
    if (!f) { perror("fopen"); return 1; }

    write_magic(f);
    wr_u32(f, GGUF_VERSION);

    const uint64_t n_tensors = 12;
    const uint64_t n_kv = 26;

    wr_u64(f, n_tensors);
    wr_u64(f, n_kv);

    // === general (3) ===
    kv_str(f, "general.architecture", "llama");                     // 1
    kv_str(f, "general.name", "tiny-llama-learning");               // 2
    kv_u32(f, "general.file_type", 0);                              // 3

    // === llama (11) ===
    kv_u32(f, "llama.context_length", CTX_LEN);                    // 4
    kv_u32(f, "llama.embedding_length", DIM);                      // 5
    kv_u32(f, "llama.block_count", N_LAYERS);                      // 6
    kv_u32(f, "llama.feed_forward_length", FFN_DIM);               // 7
    kv_u32(f, "llama.attention.head_count", N_HEADS);              // 8
    kv_u32(f, "llama.attention.head_count_kv", N_KV_HEADS);       // 9
    kv_u32(f, "llama.rope.dimension_count", ROPE_DIM);            // 10
    kv_f32(f, "llama.rope.freq_base", 10000.0f);                  // 11
    kv_str(f, "llama.rope.scaling.type", "none");                  // 12
    kv_f32(f, "llama.rope.scaling.factor", 1.0f);                 // 13
    kv_f32(f, "llama.attention.layer_norm_rms_epsilon", 1e-5f);   // 14

    // === tokenizer (12) ===
    kv_str(f, "tokenizer.ggml.model", "gpt2");                    // 15
    kv_str_array(f, "tokenizer.ggml.tokens", vocab_tokens, VOCAB_SIZE); // 16
    kv_f32_array(f, "tokenizer.ggml.scores", vocab_scores, VOCAB_SIZE); // 17
    kv_i32_array(f, "tokenizer.ggml.token_type", vocab_types, VOCAB_SIZE); // 18
    kv_str_array(f, "tokenizer.ggml.merges", bpe_merges, (uint64_t)n_merges); // 19
    kv_u32(f, "tokenizer.ggml.bos_token_id", 1);                  // 20
    kv_u32(f, "tokenizer.ggml.eos_token_id", 2);                  // 21
    kv_u32(f, "tokenizer.ggml.padding_token_id", 3);              // 22
    kv_u32(f, "tokenizer.ggml.unknown_token_id", 0);              // 23
    kv_bool(f, "tokenizer.ggml.add_bos_token", 1);                // 24
    kv_bool(f, "tokenizer.ggml.add_eos_token", 0);                // 25
    // 最简 chat template，避免 conversation 模式崩溃
    kv_str(f, "tokenizer.chat_template",                           // 26
        "{% for message in messages %}"
        "{{ message['content'] }}"
        "{% endfor %}");

    // tensor infos
    uint64_t offset = 0;
    int ti = 0;

    #define TENSOR_2D(name, ne0, ne1) do { \
        uint64_t d[] = { (uint64_t)(ne0), (uint64_t)(ne1) }; \
        uint64_t sz = tensor_info_bytes(f, name, 2, d, GGML_TYPE_F32, offset); \
        offset += sz; \
        ti++; \
    } while (0)

    #define TENSOR_1D(name, ne0) do { \
        uint64_t d[] = { (uint64_t)(ne0) }; \
        uint64_t sz = tensor_info_bytes(f, name, 1, d, GGML_TYPE_F32, offset); \
        offset += sz; \
        ti++; \
    } while (0)

    TENSOR_2D("token_embd.weight",        DIM, VOCAB_SIZE);
    TENSOR_1D("blk.0.attn_norm.weight",   DIM);
    TENSOR_2D("blk.0.attn_q.weight",      DIM, DIM);
    TENSOR_2D("blk.0.attn_k.weight",      DIM, DIM);
    TENSOR_2D("blk.0.attn_v.weight",      DIM, DIM);
    TENSOR_2D("blk.0.attn_output.weight", DIM, DIM);
    TENSOR_1D("blk.0.ffn_norm.weight",    DIM);
    TENSOR_2D("blk.0.ffn_gate.weight",    DIM, FFN_DIM);
    TENSOR_2D("blk.0.ffn_up.weight",      DIM, FFN_DIM);
    TENSOR_2D("blk.0.ffn_down.weight",    FFN_DIM, DIM);
    TENSOR_1D("output_norm.weight",        DIM);
    TENSOR_2D("output.weight",            DIM, VOCAB_SIZE);

    pad_to(f, 32);

    fwrite(token_embd,    sizeof(float), VOCAB_SIZE * DIM, f);
    fwrite(attn_norm_w,   sizeof(float), DIM, f);
    fwrite(attn_q_w,      sizeof(float), DIM * DIM, f);
    fwrite(attn_k_w,      sizeof(float), DIM * DIM, f);
    fwrite(attn_v_w,      sizeof(float), DIM * DIM, f);
    fwrite(attn_out_w,    sizeof(float), DIM * DIM, f);
    fwrite(ffn_norm_w,    sizeof(float), DIM, f);
    fwrite(ffn_gate_w,    sizeof(float), FFN_DIM * DIM, f);
    fwrite(ffn_up_w,      sizeof(float), FFN_DIM * DIM, f);
    fwrite(ffn_down_w,    sizeof(float), DIM * FFN_DIM, f);
    fwrite(output_norm_w, sizeof(float), DIM, f);
    fwrite(output_w,      sizeof(float), VOCAB_SIZE * DIM, f);

    long file_size = ftell(f);
    fclose(f);

    printf("GGUF export done: tiny_llama.gguf (%ld bytes)\n", file_size);
    printf("tensors=%d, vocab=%d, kv=%llu\n", ti, VOCAB_SIZE, (unsigned long long)n_kv);
    return 0;
}
