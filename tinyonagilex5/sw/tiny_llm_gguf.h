#ifndef TINY_LLM_GGUF_H
#define TINY_LLM_GGUF_H

// ============================================
// 模型超参数
// 设计原则: 所有数值都足够小，可以塞进 FPGA BRAM
// ============================================

#define VOCAB_SIZE   64
#define DIM          64       // 嵌入维度
#define N_HEADS      1        // 注意力头数
#define N_KV_HEADS   1        // KV 头数
#define N_LAYERS     1        // Transformer 层数
#define FFN_DIM      172      // FFN 中间维度
#define HEAD_DIM     (DIM / N_HEADS)  // 每头维度 = 64
#define CTX_LEN      128      // 最大上下文长度
#define ROPE_DIM     HEAD_DIM

// ============================================
// FPGA 资源估算 (以 float32 计):
//
// token_embd:  64 * 64       = 4096  floats  = 16 KB
// Q/K/V/O:    4 * 64 * 64    = 16384 floats  = 64 KB
// FFN:        64*172 + 172*64 + 64*172 = 33024 = 129 KB
// 其他 norm 等:                  ~256 floats  = 1 KB
// KV cache:   2 * 128 * 64   = 16384 floats  = 64 KB
// 总计约 274 KB —— 轻松放进中端 FPGA 的 BRAM
// ============================================

#endif
