# LLM Acceleration on Intel Agilex 5 FPGA

Hardware-accelerated LLM inference for Llama and lightweight language models on Intel Agilex 5 FPGA. This project explores multiple hardware-software co-design approaches for running small to medium language models with FPGA acceleration of compute-intensive operations.

## Features

- **FPGA-accelerated matrix operations** with configurable PE arrays (FP32 and INT8)
- **Multiple model support**: Llama2 (15M-7B), TinyLlama, and GGUF format models
- **Hardware-software partitioning** for optimal throughput and resource utilization
- **Dual backend execution**: CPU reference and FPGA accelerated paths
- **DMA-based data transfer** with shared memory between HPS and FPGA fabric
- **Complete development flow**: RTL design, HLS synthesis, cross-compilation, deployment automation
- **Comprehensive testing**: Unit tests, board-level validation, inference verification

## Architecture

The system partitions LLM inference across ARM HPS (Hard Processor System) and FPGA fabric:

- **Host (ARM Cortex-A)**: Model orchestration, tokenization, non-linear activations, control flow
- **FPGA Fabric**: Matrix-vector/matrix-matrix multiplication, custom compute kernels
- **Memory**: Shared DDR4 with DMA for efficient weight and activation transfer

Current implementations:
- **llama2-agilex5-0906**: Production implementation with validated board bringup
- **tinyonagilex5**: Minimal accelerator with GGUF format support
- **tinyonfpga**: Simulation-oriented FPGA implementation
- **tinyllm/tinygguf**: CPU reference and model conversion utilities

## Prerequisites

### Hardware
- Intel Agilex 5E Development Kit (DE25-Standard or compatible)
- Minimum 1GB DDR4 system memory

### Software
- Intel Quartus Prime Pro Edition (25.1.1 or later)
- ARM cross-compilation toolchain (`aarch64-linux-gnu-gcc`)
- CMake 3.18+ or Make
- Python 3.11+ (for test vectors and analysis tools)

## Quick Start

### Using the Main Implementation (llama2-agilex5-0906)

```bash
cd llama2-agilex5-0906

# Build hardware (requires Quartus environment)
./hw/scripts/build.sh

# Cross-compile software
cd sw
make CROSS_COMPILE=aarch64-linux-gnu-

# Deploy to board
scp run_fpga root@<board_ip>:/root/
scp tests/models/stories15M.bin root@<board_ip>:/root/

# Run inference on target
ssh root@<board_ip>
./run_fpga stories15M.bin
```

### Using TinyOnAgilex5 (GGUF Support)

```bash
cd tinyonagilex5/sw

# Build with FPGA backend
make

# Run inference
./tiny_llm_fpga tiny_llama.gguf "Once upon a time"

# Or CPU-only reference
./tiny_llm_cpu tiny_llama.gguf "Once upon a time"
```

## Project Structure

```
.
├── llama2-agilex5-0906/      # Main production implementation (validated on hardware)
│   ├── hw/                    # Hardware design files
│   │   ├── rtl/              # SystemVerilog accelerator cores
│   │   ├── ip/               # Custom IP components
│   │   └── ghrd/             # Golden hardware reference design
│   ├── sw/                    # Software runtime
│   │   ├── accel/            # FPGA accelerator API
│   │   ├── ref/              # CPU reference implementation
│   │   └── tools/            # Weight export and comparison
│   ├── linux/                 # Device tree overlays and boot config
│   ├── tests/                 # Board-level test suite
│   └── docs/                  # Architecture and bringup notes
│
├── tinyonagilex5/            # Minimal LLM accelerator with GGUF support
│   ├── hw/rtl/               # Accelerator units (matmul, RMSNorm, RoPE, etc.)
│   ├── sw/                    # Lightweight runtime
│   └── docs/                  # Design documentation
│
├── tinyonfpga/               # FPGA simulation framework
├── tinyllm/                  # CPU-only reference implementation
└── tinygguf/                 # GGUF model export utilities
```

## Building

### Hardware Build (llama2-agilex5-0906)

```bash
cd llama2-agilex5-0906/hw/scripts

# Full Quartus synthesis and place-route (2-4 hours)
./build.sh

# Generate RBF bitstream for configuration
./gen_rbf.sh
```

The build produces bitstream files in `hw/ghrd/output_files/`.

### Software Build

```bash
cd llama2-agilex5-0906/sw

# Cross-compile for ARM target
make CROSS_COMPILE=aarch64-linux-gnu-

# Or native x86 build for simulation
make
```

### Building Other Variants

```bash
# TinyOnAgilex5
cd tinyonagilex5/sw
make              # CPU version
make fpga         # FPGA-accelerated version

# GGUF export tools
cd tinygguf
gcc export_gguf_v2.c -o export_gguf -lm
```

## Board Setup and Deployment

### Initial Board Configuration

See [`llama2-agilex5-0906/docs/`](llama2-agilex5-0906/docs/) for detailed bringup instructions:

1. **Program FPGA**: Load bitstream via JTAG or QSPI flash
2. **Boot Linux**: Ensure device tree includes FPGA region and reserved memory
3. **Configure shared memory**: Use device tree overlay in `linux/dts/`
4. **Set permissions**: Enable userspace MMIO access to FPGA registers

### Running Tests

```bash
cd llama2-agilex5-0906/tests

# DDR coherency test (HPS ↔ FPGA data exchange)
./test_ddr_hps_fpga_exchange.sh

# FPGA DSP resource validation
./test_fp32_dsp_board.sh

# Variable-size GEMV kernel test
./test_gemv_variable_fp32

# Full inference smoke test
cd ../sw
./run_fpga tests/models/stories15M.bin
```

Test logs are saved to `tests/logs/`.

## Model Support

### Currently Supported

- **Llama2**: 15M, 42M, 110M parameter models
- **Stories models**: Minimal Llama2 variants for validation
- **GGUF format**: Via tinyonagilex5 and tinygguf tools

### Planned Support

- **Llama 2.5B** models
- **llama.cpp** integration for broader model compatibility
- **Quantized models**: INT8 and mixed-precision inference

## Performance

Preliminary results on Agilex 5E Development Kit:

| Implementation      | Model       | Backend | Tokens/sec | Notes                  |
| ------------------- | ----------- | ------- | ---------- | ---------------------- |
| llama2-agilex5-0906 | Stories 15M | CPU     | ~12        | ARM Cortex-A reference |
| llama2-agilex5-0906 | Stories 15M | FPGA    | ~48        | FP32 PE array, 250MHz  |
| tinyonagilex5       | TinyLlama   | FPGA    | TBD        | Under characterization |

See `tests/logs/` for detailed timing breakdowns.

## Configuration

### Hardware Parameters

Edit board configuration in `llama2-agilex5-0906/hw/ghrd/qsys_top.qsys`:
- PE array dimensions
- Clock frequencies
- Memory controller settings

### Runtime Configuration

Model and inference parameters are typically specified via command-line:

```bash
# FPGA-accelerated inference with timing
./run_fpga_timing stories15M.bin

# CPU reference for golden validation
./run_cpu_ref stories15M.bin
```

## Documentation

### llama2-agilex5-0906
- Architecture notes: `docs/01_architecture.md`, `docs/02_regmap.md`
- Bringup guide: `docs/03_bringup_shturl`, `docs/Agilex 5E(DE25-Standard)design.md`
- Implementation series: `docs/[fpga]llama2_c移植到agilex5设计的实现(5-9).md`

### Design Resources
- DDR validation: `docs/[llama移植]ddr_test_master验证.md`
- Memory layout: Check device tree overlays in `linux/dts/`

## Tools

### Weight Conversion

```bash
# Export PyTorch model to binary format
cd llama2-agilex5-0906/sw/tools
python export_weights.py --model <checkpoint.pth> --output weights.bin

# Convert to GGUF format
cd ../../../tinygguf
./export_gguf <input.bin> <output.gguf>
```

### Inference Validation

```bash
# Compare FPGA vs CPU outputs
cd llama2-agilex5-0906/sw/tools
python compare.py --fpga out_fpga.txt --cpu out_cpu.txt
```

## Troubleshooting

### FPGA Not Accessible

Check that:
1. Bitstream is loaded (`lspci` should show Intel FPGA device)
2. Device tree includes FPGA bridge and memory regions
3. `/dev/mem` or UIO device has correct permissions

### Memory Allocation Failures

Ensure reserved memory region is defined in device tree (see `linux/dts/reserved-memory.dtsi`).

### Performance Lower Than Expected

- Verify FPGA clock frequency: check `hw/ghrd/qsys_top.qsys` PLL settings
- Profile with timing version: `./run_fpga_timing`
- Check for DDR bandwidth bottlenecks using test tools in `tests/board/`

## Contributing

When adding new accelerator units:
1. Add RTL to `hw/rtl/`
2. Create corresponding test in `hw/tb/`
3. Update software API in `sw/accel/`
4. Add validation test to `tests/`

## Roadmap

- [x] Llama2 15M/42M inference on Agilex 5E
- [x] GGUF format support
- [x] FP32 GEMV acceleration
- [ ] INT8 quantized inference
- [ ] Llama 2.5B model support
- [ ] llama.cpp backend integration
- [ ] Multi-layer pipelining
- [ ] On-chip weight caching for small models

## License

See individual LICENSE files in subdirectories. Core implementations follow their respective upstream licenses.

## References

- Intel Agilex 5 FPGA Documentation
- [llama2.c](https://github.com/karpathy/llama2.c) by Andrej Karpathy
- [llama.cpp](https://github.com/ggerganov/llama.cpp) GGUF specification

---

**Status**: Active development. `llama2-agilex5-0906` validated on hardware. Other variants under integration testing.