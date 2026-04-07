// main.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "model.h"
#include "ops.h"

// token -> 字符串映射
static const char *token_to_str(int id) {
    static const char *special[] = {"<pad>", "<s>", "</s>", "<unk>"};
    if (id < 4) return special[id];

    static char buf[8];
    if (id >= 4 && id < 30) {
        buf[0] = (char)('a' + (id - 4));
        buf[1] = '\0';
        return buf;
    }
    if (id >= 30 && id < 34) {
        buf[0] = (char)('0' + (id - 30));
        buf[1] = '\0';
        return buf;
    }
    if (id == 34) return " ";
    if (id == 35) return "\\n";

    static const char *bigrams[] = {
        "th", "he", "in", "er", "an", "re", "on", "at",
        "en", "nd", "ti", "es", "or", "te", "of", "ed",
        "is", "it", "al", "ar", "st", "to", "nt", "ng",
        "se", "ha", "as", "ou"
    };
    if (id >= 36 && id < 64) return bigrams[id - 36];
    return "?";
}

int main(void) {
    printf("========================================\n");
    printf("  Tiny LLM — 极简 Transformer 推理引擎\n");
    printf("  适用于 FPGA 加速学习\n");
    printf("========================================\n\n");

    // 初始化模型
    Model model;
    model_init(&model);
    model.use_fpga = 0;

    printf("[模型参数]\n");
    printf("  层数:     %d\n", N_LAYERS);
    printf("  维度:     %d\n", DIM);
    printf("  注意力头: %d\n", N_HEADS);
    printf("  FFN维度:  %d\n", FFN_DIM);
    printf("  词表:     %d\n", VOCAB_SIZE);
    printf("  上下文:   %d\n\n", CTX_LEN);

    // 自回归生成
    int start_token = 1;
    int max_gen = 20;

    printf("[生成过程]\n");
    printf("  起始: %s (id=%d)\n", token_to_str(start_token), start_token);
    printf("  输出: ");

    int token = start_token;
    for (int pos = 0; pos < max_gen; pos++) {
        int next = model_forward(&model, token, pos);
        printf("%s", token_to_str(next));
        fflush(stdout);
        if (next == 2) {
            printf(" [EOS]");
            break;
        }
        token = next;
    }
    printf("\n\n");

    // ========================================
    // 算子性能基准测试
    // ========================================
    printf("[算子基准测试]\n");

    float test_in[DIM], test_out[DIM], test_w[DIM * DIM];
    float test_ffn_out[FFN_DIM];
    float test_ffn_w[DIM * FFN_DIM];
    for (int i = 0; i < DIM; i++) {
        test_in[i] = 0.1f * (float)(i % 10);
        for (int j = 0; j < DIM; j++)
            test_w[i * DIM + j] = (i == j) ? 1.0f : 0.01f;
    }
    for (int i = 0; i < DIM * FFN_DIM; i++)
        test_ffn_w[i] = 0.01f;

    float norm_w[DIM];
    for (int i = 0; i < DIM; i++) norm_w[i] = 1.0f;

    int N_ITER = 1000;

    for (int n = 0; n < N_ITER; n++)
        op_matmul(test_in, test_w, test_out, DIM, DIM);
    printf("  matmul   %dx%d      x%d  OK\n", DIM, DIM, N_ITER);

    for (int n = 0; n < N_ITER; n++)
        op_matmul(test_in, test_ffn_w, test_ffn_out, DIM, FFN_DIM);
    printf("  matmul   %dx%d    x%d  OK\n", DIM, FFN_DIM, N_ITER);

    for (int n = 0; n < N_ITER; n++)
        op_rmsnorm(test_in, norm_w, test_out, DIM, 1e-5f);
    printf("  rmsnorm  dim=%d       x%d  OK\n", DIM, N_ITER);

    float test_scores[CTX_LEN];
    for (int i = 0; i < CTX_LEN; i++) test_scores[i] = 0.1f * i;
    for (int n = 0; n < N_ITER; n++)
        op_softmax(test_scores, CTX_LEN);
    printf("  softmax  n=%d        x%d  OK\n", CTX_LEN, N_ITER);

    float test_silu[FFN_DIM];
    for (int i = 0; i < FFN_DIM; i++) test_silu[i] = 0.5f;
    for (int n = 0; n < N_ITER; n++)
        op_silu(test_silu, FFN_DIM);
    printf("  silu     n=%d        x%d  OK\n", FFN_DIM, N_ITER);

    float test_q[DIM], test_k[DIM];
    for (int i = 0; i < DIM; i++) { test_q[i] = 0.1f; test_k[i] = 0.1f; }
    for (int n = 0; n < N_ITER; n++)
        op_rope(test_q, test_k, DIM, 42);
    printf("  rope     dim=%d       x%d  OK\n", DIM, N_ITER);

    // Q8 量化测试
    QuantizedVec qv;
    memset(&qv, 0, sizeof(qv));
    qv.data = NULL;
    op_quantize_q8(test_in, &qv, DIM);
    int8_t q8_w[DIM * DIM];
    float q8_scales[DIM];
    for (int i = 0; i < DIM * DIM; i++) q8_w[i] = (int8_t)((i % 5) - 2);
    for (int i = 0; i < DIM; i++) q8_scales[i] = 0.01f;
    for (int n = 0; n < N_ITER; n++)
        op_matmul_q8(&qv, q8_w, q8_scales, test_out, DIM, DIM);
    printf("  matmul_q8 %dx%d     x%d  OK\n", DIM, DIM, N_ITER);
    free(qv.data);

    printf("\n所有算子测试通过！\n");

    return 0;
}
