# Makefile for Agilex 5 HPS (ARM cross-compile)

CC ?= cc
CFLAGS  = -O2 -Wall -Wextra -std=c99
LDFLAGS = -lm

all: tiny_llm_cpu tiny_llm_fpga export_gguf benchmark

tiny_llm_cpu: main.c model.c ops.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

tiny_llm_fpga: main.c model.c ops_fpga.c fpga_driver.c
	$(CC) $(CFLAGS) -DUSE_FPGA -o $@ $^ $(LDFLAGS)

export_gguf: export_gguf.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

benchmark: benchmark.c ops.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f tiny_llm_cpu tiny_llm_fpga export_gguf benchmark tiny_llama.gguf

.PHONY: all clean
