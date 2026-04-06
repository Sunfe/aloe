#ifndef TINY_LLM_GGUF_H
#define TINY_LLM_GGUF_H

#define VOCAB_SIZE   64
#define DIM          64
#define N_HEADS      1
#define N_KV_HEADS   1              // ← 加这行
#define N_LAYERS     1
#define FFN_DIM      172
#define HEAD_DIM     (DIM / N_HEADS)
#define CTX_LEN      128
#define ROPE_DIM     HEAD_DIM       // ← 加这行

#endif
