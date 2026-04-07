# Makefile for Tiny LLM FPGA Project

CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c99
LDFLAGS = -lm

# ========================================
# 目标
# ========================================

all: tiny_llm export_gguf

# 主推理程序 (CPU 版本)
tiny_llm: main.c model.c ops.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# GGUF 导出器
export_gguf: export_gguf.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# 生成 GGUF 文件
tiny_llama.gguf: export_gguf
	./export_gguf

# FPGA 仿真版本 (替换 ops.c 为 fpga 版本)
tiny_llm_fpga: main.c model.c ops_fpga_sim.c ops.c
	$(CC) $(CFLAGS) -DUSE_FPGA -o $@ main.c model.c ops_fpga_sim.c ops.c $(LDFLAGS)

# 运行测试
run: tiny_llm
	./tiny_llm

# 导出并用 llama.cpp 测试
test_gguf: tiny_llama.gguf
	@echo "========================================"
	@echo "请运行:"
	@echo "  llama-cli -m tiny_llama.gguf -p \"hello\" -n 20 --temp 0"
	@echo "========================================"

clean:
	rm -f tiny_llm export_gguf tiny_llm_fpga tiny_llama.gguf

.PHONY: all run test_gguf clean
