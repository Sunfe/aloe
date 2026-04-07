// benchmark.c
// CPU vs FPGA 算子性能对比

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "ops.h"
#include "tiny_llm_gguf.h"

#ifdef USE_FPGA
#include "fpga_driver.h"
extern int  ops_fpga_init(void);
extern void ops_fpga_close(void);
#endif

// 计时辅助
static double get_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

// CPU 版矩阵乘 (直接内联，不经过 FPGA)
static void cpu_matmul(const float *in, const float *w,
                       float *out, int in_dim, int out_dim) {
    for (int o = 0; o < out_dim; o++) {
        float sum = 0;
        for (int i = 0; i < in_dim; i++)
            sum += in[i] * w[i * out_dim + o];
        out[o] = sum;
    }
}

int main(void) {
    printf("╔══════════════════════════════════════════╗\n");
    printf("║  Tiny LLM — CPU vs FPGA 性能对比         ║\n");
    printf("║  Platform: Intel Agilex 5                ║\n");
    printf("╚══════════════════════════════════════════╝\n\n");

    int N = 1000;  // 每个算子测试次数

    // 准备测试数据
    float vec_in[DIM], vec_out[DIM];
    float mat_w[DIM * DIM];
    float ffn_w[DIM * FFN_DIM], ffn_out[FFN_DIM];
    float norm_w[DIM];

    srand(42);
    for (int i = 0; i < DIM; i++) {
        vec_in[i] = (float)(rand() % 100 - 50) / 50.0f;
        norm_w[i] = 1.0f;
    }
    for (int i = 0; i < DIM * DIM; i++)
        mat_w[i] = (float)(rand() % 100 - 50) / 500.0f;
    for (int i = 0; i < DIM * FFN_DIM; i++)
        ffn_w[i] = (float)(rand() % 100 - 50) / 500.0f;

    // ========== CPU 基准 ==========
    printf("[CPU 基准测试] (%d 次迭代)\n", N);
    printf("─────────────────────────────────────────\n");

    double t0, t1;

    // MatMul DIM×DIM
    t0 = get_time_ms();
    for (int n = 0; n < N; n++)
        cpu_matmul(vec_in, mat_w, vec_out, DIM, DIM);
    t1 = get_time_ms();
    double cpu_mm = (t1 - t0) / N;
    printf("  matmul  %3dx%-3d   : %8.3f ms/op  (%6.1f MFLOPS)\n",
           DIM, DIM, cpu_mm,
           (2.0 * DIM * DIM) / (cpu_mm * 1000.0));

    // MatMul DIM×FFN_DIM
    t0 = get_time_ms();
    for (int n = 0; n < N; n++)
        cpu_matmul(vec_in, ffn_w, ffn_out, DIM, FFN_DIM);
    t1 = get_time_ms();
    double cpu_mm_ffn = (t1 - t0) / N;
    printf("  matmul  %3dx%-3d  : %8.3f ms/op  (%6.1f MFLOPS)\n",
           DIM, FFN_DIM, cpu_mm_ffn,
           (2.0 * DIM * FFN_DIM) / (cpu_mm_ffn * 1000.0));

    // RMSNorm
    t0 = get_time_ms();
    for (int n = 0; n < N; n++) {
        float sq = 0;
        for (int i = 0; i < DIM; i++) sq += vec_in[i]*vec_in[i];
        float inv = 1.0f / sqrtf(sq/DIM + 1e-5f);
        for (int i = 0; i < DIM; i++) vec_out[i] = vec_in[i]*inv*norm_w[i];
    }
    t1 = get_time_ms();
    double cpu_rn = (t1 - t0) / N;
    printf("  rmsnorm dim=%-3d   : %8.3f ms/op\n", DIM, cpu_rn);

    // Softmax
    float scores[CTX_LEN];
    for (int i = 0; i < CTX_LEN; i++) scores[i] = (float)(i - 64) / 10.0f;
    t0 = get_time_ms();
    for (int n = 0; n < N; n++) {
        float mx = scores[0];
        for (int i=1;i<CTX_LEN;i++) if(scores[i]>mx) mx=scores[i];
        float sm=0;
        for (int i=0;i<CTX_LEN;i++) {scores[i]=expf(scores[i]-mx); sm+=scores[i];}
        for (int i=0;i<CTX_LEN;i++) scores[i]/=sm;
    }
    t1 = get_time_ms();
    double cpu_sm = (t1 - t0) / N;
    printf("  softmax n=%-3d     : %8.3f ms/op\n", CTX_LEN, cpu_sm);

#ifdef USE_FPGA
    // ========== FPGA 测试 ==========
    printf("\n[FPGA 加速测试] (%d 次迭代)\n", N);
    printf("─────────────────────────────────────────\n");

    if (ops_fpga_init() < 0) {
        printf("FPGA 初始化失败，跳过\n");
        return 1;
    }

    // MatMul DIM×DIM
    t0 = get_time_ms();
    for (int n = 0; n < N; n++)
        op_matmul(vec_in, mat_w, vec_out, DIM, DIM);
    t1 = get_time_ms();
    double fpga_mm = (t1 - t0) / N;
    printf("  matmul  %3dx%-3d   : %8.3f ms/op  (加速比: %.1fx)\n",
           DIM, DIM, fpga_mm, cpu_mm / fpga_mm);

    // MatMul DIM×FFN_DIM
    t0 = get_time_ms();
    for (int n = 0; n < N; n++)
        op_matmul(vec_in, ffn_w, ffn_out, DIM, FFN_DIM);
    t1 = get_time_ms();
    double fpga_mm_ffn = (t1 - t0) / N;
    printf("  matmul  %3dx%-3d  : %8.3f ms/op  (加速比: %.1fx)\n",
           DIM, FFN_DIM, fpga_mm_ffn, cpu_mm_ffn / fpga_mm_ffn);

    // RMSNorm
    t0 = get_time_ms();
    for (int n = 0; n < N; n++)
        op_rmsnorm(vec_in, norm_w, vec_out, DIM, 1e-5f);
    t1 = get_time_ms();
    double fpga_rn = (t1 - t0) / N;
    printf("  rmsnorm dim=%-3d   : %8.3f ms/op  (加速比: %.1fx)\n",
           DIM, fpga_rn, cpu_rn / fpga_rn);

    // Softmax
    for (int i = 0; i < CTX_LEN; i++) scores[i] = (float)(i-64)/10.0f;
    t0 = get_time_ms();
    for (int n = 0; n < N; n++)
        op_softmax(scores, CTX_LEN);
    t1 = get_time_ms();
    double fpga_sm = (t1 - t0) / N;
    printf("  softmax n=%-3d     : %8.3f ms/op  (加速比: %.1fx)\n",
           CTX_LEN, fpga_sm, cpu_sm / fpga_sm);

    // ========== 总结 ==========
    printf("\n[端到端推理估算]\n");
    printf("─────────────────────────────────────────\n");

    // 一次推理的主要 matmul 次数:
    // Q,K,V,O: 4x DIMxDIM
    // FFN gate,up: 2x DIMxFFN
    // FFN down: 1x FFNxDIM
    // Output: 1x DIMxVOCAB
    int n_matmul_small = 5;  // DIMxDIM
    int n_matmul_large = 3;  // DIMxFFN

    double cpu_total = n_matmul_small * cpu_mm +
                       n_matmul_large * cpu_mm_ffn +
                       2 * cpu_rn + cpu_sm;
    double fpga_total = n_matmul_small * fpga_mm +
                        n_matmul_large * fpga_mm_ffn +
                        2 * fpga_rn + fpga_sm;

    printf("  CPU  推理延迟: %.3f ms/token\n", cpu_total);
    printf("  FPGA 推理延迟: %.3f ms/token\n", fpga_total);
    printf("  整体加速比:    %.1fx\n", cpu_total / fpga_total);

    ops_fpga_close();
#endif

    printf("\n完成。\n");
    return 0;
}
