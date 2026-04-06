#include <stdio.h>
#include <string.h>

#define VOCAB_SIZE 32
#define DIM 64
#define FFN_DIM 128

// ======================
// 微模型权重（就是“张量”）
// ======================
float token_embd[VOCAB_SIZE][DIM] = {0};  // 词嵌入
float q_w[DIM][DIM] = {0};                // Q 矩阵
float k_w[DIM][DIM] = {0};                // K 矩阵
float v_w[DIM][DIM] = {0};                // V 矩阵
float out_w[DIM][DIM] = {0};              // 注意力输出
float ffn_up[DIM][FFN_DIM] = {0};         // FFN up
float ffn_down[FFN_DIM][DIM] = {0};       // FFN down
float output_w[VOCAB_SIZE][DIM] = {0};    // 输出层

// ======================
// 基础算子
// ======================
void matmul_1d_2d(float *in, float *w, float *out, int in_dim, int out_dim) {
    for (int o = 0; o < out_dim; o++) {
        float sum = 0.0f;
        for (int i = 0; i < in_dim; i++) {
            sum += in[i] * w[i * out_dim + o];
        }
        out[o] = sum;
    }
}

void relu(float *x, int n) {
    for (int i = 0; i < n; i++) {
        if (x[i] < 0) x[i] = 0;
    }
}

int argmax(float *x, int n) {
    int m = 0;
    for (int i = 1; i < n; i++) {
        if (x[i] > x[m]) m = i;
    }
    return m;
}

// 极简单头注意力
void attention(float *q, float *k, float *v, float *out, int dim) {
    float scale = 1.0f / 8.0f;
    float score = 0.0f;
    for (int i = 0; i < dim; i++) {
        score += q[i] * k[i];
    }
    score *= scale;

    float weight = 1.0f;
    for (int i = 0; i < dim; i++) {
        out[i] = weight * v[i];
    }
}

// ======================
// 一次推理：输入token，输出下一个token
// ======================
int infer(int token) {
    float x[DIM], q[DIM], k[DIM], v[DIM];
    float attn_out[DIM], ffn_buf[FFN_DIM];

    // 1. 词嵌入查表
    memcpy(x, token_embd[token], sizeof(x));

    // 2. 计算 Q K V
    matmul_1d_2d(x, (float*)q_w, q, DIM, DIM);
    matmul_1d_2d(x, (float*)k_w, k, DIM, DIM);
    matmul_1d_2d(x, (float*)v_w, v, DIM, DIM);

    // 3. 注意力
    attention(q, k, v, attn_out, DIM);

    // 4. 输出投影
    matmul_1d_2d(attn_out, (float*)out_w, x, DIM, DIM);

    // 5. FFN
    matmul_1d_2d(x, (float*)ffn_up, ffn_buf, DIM, FFN_DIM);
    relu(ffn_buf, FFN_DIM);
    matmul_1d_2d(ffn_buf, (float*)ffn_down, x, FFN_DIM, DIM);

    // 6. 输出下一个token概率
    float logits[VOCAB_SIZE];
    matmul_1d_2d(x, (float*)output_w, logits, DIM, VOCAB_SIZE);

    return argmax(logits, VOCAB_SIZE);
}

// ======================
// 给权重随便填点测试值
// ======================
void init_weights(void) {
    for (int i = 0; i < DIM; i++) {
        token_embd[1][i] = 0.1f;
        q_w[i][i] = 1.0f;
        k_w[i][i] = 1.0f;
        v_w[i][i] = 1.0f;
        out_w[i][i] = 1.0f;
        output_w[10][i] = 0.1f;
    }
    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < FFN_DIM; j++) {
            ffn_up[i][j] = 0.01f;
            ffn_down[j][i] = 0.01f;
        }
    }
}

// ======================
// 主函数：跑一遍
// ======================
int main(void) {
    init_weights();
    int next_token = infer(1);
    printf("输入token: 1\n输出下一个token: %d\n", next_token);
    return 0;
}
