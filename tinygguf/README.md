gcc -O2 -o export_gguf export_gguf.c -lm
./export_gguf
cp tiny_llama.gguf llama.cpp/models/

llama.cpp/build/bin/llama-cli -m models/tiny_llama.gguf -p "hello" -n 10

Log

```
liaozhichengs-MacBook-Pro:llama.cpp liaozhic$ ./build/bin/llama-cli -m models/tiny_llama.gguf -p "hello" -n 10
ggml_metal_device_init: tensor API disabled for pre-M5 and pre-A19 devices
ggml_metal_library_init: using embedded metal library
ggml_metal_library_init: loaded in 0.006 sec
ggml_metal_rsets_init: creating a residency set collection (keep_alive = 180 s)
ggml_metal_device_init: GPU name:   MTL0
ggml_metal_device_init: GPU family: MTLGPUFamilyApple9  (1009)
ggml_metal_device_init: GPU family: MTLGPUFamilyCommon3 (3003)
ggml_metal_device_init: GPU family: MTLGPUFamilyMetal4  (5002)
ggml_metal_device_init: simdgroup reduction   = true
ggml_metal_device_init: simdgroup matrix mul. = true
ggml_metal_device_init: has unified memory    = true
ggml_metal_device_init: has bfloat            = true
ggml_metal_device_init: has tensor            = false
ggml_metal_device_init: use residency sets    = true
ggml_metal_device_init: use shared buffers    = true
ggml_metal_device_init: recommendedMaxWorkingSetSize  = 40200.90 MB
register_backend: registered backend MTL (1 devices)
register_device: registered device MTL0 (Apple M4 Pro)
register_backend: registered backend BLAS (1 devices)
register_device: registered device BLAS (Accelerate)
register_backend: registered backend CPU (1 devices)
register_device: registered device CPU (Apple M4 Pro)

Loading model...  


▄▄ ▄▄
██ ██
██ ██  ▀▀█▄ ███▄███▄  ▀▀█▄    ▄████ ████▄ ████▄
██ ██ ▄█▀██ ██ ██ ██ ▄█▀██    ██    ██ ██ ██ ██
██ ██ ▀█▄██ ██ ██ ██ ▀█▄██ ██ ▀████ ████▀ ████▀
                                    ██    ██
                                    ▀▀    ▀▀

build      : b8538-9900b29c3
model      : tiny_llama.gguf
modalities : text

available commands:
  /exit or Ctrl+C     stop or exit
  /regen              regenerate the last response
  /clear              clear the chat history
  /read               add a text file


> hello

token_25token_37token_55token_25token_25token_10token_43token_18

[ Prompt: 695.9 t/s | Generation: 2219.8 t/s ]


```

v2:

完善 tokenizer 部分

gcc -O2 -o export_gguf export_gguf.c -lm

./export_gguf

cp tiny_llama.gguf llama.cpp/models/

./llama.cpp/build/bin/llama-cli -m ./llama.cpp/models/tiny_llama.gguf -p "the" -n 20 --temp 0.0 -no-cnv

```
liaozhichengs-MacBook-Pro:tinygguf liaozhic$ gcc -O2 -o export_gguf_v2 export_gguf_v2.c -lm
liaozhichengs-MacBook-Pro:tinygguf liaozhic$ ./export_gguf_v2 
GGUF export done: tiny_llama.gguf (234528 bytes)
tensors=12, vocab=64, kv=26
liaozhichengs-MacBook-Pro:tinygguf liaozhic$ 
liaozhichengs-MacBook-Pro:llama.cpp liaozhic$ ./build/bin/llama-cli -m ./models/tiny_llama.gguf -p "the" -n 20 --temp 0.0 -no-cnv
ggml_metal_device_init: tensor API disabled for pre-M5 and pre-A19 devices
ggml_metal_library_init: using embedded metal library
ggml_metal_library_init: loaded in 0.017 sec
ggml_metal_rsets_init: creating a residency set collection (keep_alive = 180 s)
ggml_metal_device_init: GPU name:   MTL0
ggml_metal_device_init: GPU family: MTLGPUFamilyApple9  (1009)
ggml_metal_device_init: GPU family: MTLGPUFamilyCommon3 (3003)
ggml_metal_device_init: GPU family: MTLGPUFamilyMetal4  (5002)
ggml_metal_device_init: simdgroup reduction   = true
ggml_metal_device_init: simdgroup matrix mul. = true
ggml_metal_device_init: has unified memory    = true
ggml_metal_device_init: has bfloat            = true
ggml_metal_device_init: has tensor            = false
ggml_metal_device_init: use residency sets    = true
ggml_metal_device_init: use shared buffers    = true
ggml_metal_device_init: recommendedMaxWorkingSetSize  = 40200.90 MB
register_backend: registered backend MTL (1 devices)
register_device: registered device MTL0 (Apple M4 Pro)
register_backend: registered backend BLAS (1 devices)
register_device: registered device BLAS (Accelerate)
register_backend: registered backend CPU (1 devices)
register_device: registered device CPU (Apple M4 Pro)
--no-conversation is not supported by llama-cli
please use llama-completion instead

Loading model...  


▄▄ ▄▄
██ ██
██ ██  ▀▀█▄ ███▄███▄  ▀▀█▄    ▄████ ████▄ ████▄
██ ██ ▄█▀██ ██ ██ ██ ▄█▀██    ██    ██ ██ ██ ██
██ ██ ▀█▄██ ██ ██ ██ ▀█▄██ ██ ▀████ ████▀ ████▀
                                    ██    ██
                                    ▀▀    ▀▀

build      : b8538-9900b29c3
model      : tiny_llama.gguf
modalities : text

available commands:
  /exit or Ctrl+C     stop or exit
  /regen              regenerate the last response
  /clear              clear the chat history
  /read               add a text file


> the

haal2nkndtalfqermfatjoukre

[ Prompt: 60.7 t/s | Generation: 737.2 t/s ]

> 

```

## 和原始 tiny_llm.c 的对应关系

| 你的 tiny_llm.c      | GGUF 中的张量              | 说明                                         |
| -------------------- | -------------------------- | -------------------------------------------- |
| `token_embd[32][64]` | `token_embd.weight`        | 词嵌入，扩展到64词                           |
| `q_w[64][64]`        | `blk.0.attn_q.weight`      | Q 投影矩阵                                   |
| `k_w[64][64]`        | `blk.0.attn_k.weight`      | K 投影矩阵                                   |
| `v_w[64][64]`        | `blk.0.attn_v.weight`      | V 投影矩阵                                   |
| `out_w[64][64]`      | `blk.0.attn_output.weight` | 注意力输出投影                               |
| `ffn_up[64][128]`    | `blk.0.ffn_up.weight`      | FFN 上投影                                   |
| `ffn_down[128][64]`  | `blk.0.ffn_down.weight`    | FFN 下投影                                   |
| (无)                 | `blk.0.ffn_gate.weight`    | LLaMA 的 SwiGLU gate，你原来用 ReLU 没有这个 |
| (无)                 | `blk.0.attn_norm.weight`   | RMSNorm，你原来省略了                        |
| (无)                 | `blk.0.ffn_norm.weight`    | RMSNorm，你原来省略了                        |
| `output_w[32][64]`   | `output.weight`            | 输出层                                       |

你的原始代码是一个极简骨架，GGUF 版本补齐了 LLaMA 架构要求的 RMSNorm 和 SwiGLU gate，这样 llama.cpp 才能正确加载。整体思路完全一致，只是格式和命名规范对齐了。
