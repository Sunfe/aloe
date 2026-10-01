# GEMV input readback mode baseline

Compare `GEMV_MODE=verify` and `GEMV_MODE=perf` using the same executable.

`verify` performs full W/x readback comparisons before START and after
completion. `perf` skips those comparisons.

Both modes retain CPU reference computation, bit-exact Q/K/V output
validation, guard checks, output poison checks, memory barriers,
CSR checks, and completion diagnostics. W/x are copied on every call.

## Configuration

- Board: Terasic DE25-Standard, Agilex 5E
- Model: stories15M.bin
- Tokenizer: tokenizer.bin
- Model dimension: 288
- Layers: 6
- FPGA operations: Q/K/V in every layer
- Executable: run_fpga_readback
- OpenMP threads: 1
- Decoding: greedy
- Seed: 1
- Step limit: 8
- Prompt: "Once upon a time"
- Run order: verify, then perf
- GEMV_CLOCK_HZ: unset

## Commands

```bash
sudo env GEMV_MODE=verify OMP_NUM_THREADS=1 \
    ./run_fpga_readback stories15M.bin \
    -z tokenizer.bin -m generate \
    -t 0 -s 1 -n 8 -i "Once upon a time" \
    > verify.txt 2> verify.log &&
sudo env GEMV_MODE=perf OMP_NUM_THREADS=1 \
    ./run_fpga_readback stories15M.bin \
    -z tokenizer.bin -m generate \
    -t 0 -s 1 -n 8 -i "Once upon a time" \
    > perf.txt 2> perf.log
```

Compare generated output:

```bash
cmp verify.txt perf.txt
```

## Results

Both modes completed 8 forwards and 144 GEMV calls. All Q/K/V results
passed bit-exact CPU/FPGA comparison. Generated stdout was identical.

Timing values below are milliseconds per forward unless otherwise noted.

| Metric                           |    verify |      perf |
| -------------------------------- | --------: | --------: |
| Mean forward time                |  2239.840 |  1026.302 |
| Accelerator API                  |  1809.448 |   840.007 |
| Input precheck                   |   487.015 |     2.215 |
| Input postcheck                  |   485.574 |     0.577 |
| W copy to DDR                    |   167.264 |   167.743 |
| START to DONE                    |   666.068 |   665.830 |
| CPU Q/K/V reference              |    36.715 |    18.212 |
| Remaining forward                |   391.773 |   165.469 |
| Reported generation speed, tok/s |  0.516262 |  0.977517 |
| FPGA cycles, total               | 531429969 | 531423308 |

Removing full W/x readback reduced accelerator API time by approximately
969 ms per forward. Weight-copy time, START-to-DONE time, and FPGA cycles
remained approximately unchanged.

The observed full-forward speedup was approximately 2.18x. CPU reference
and remaining-forward time also decreased between runs, so this entire
speedup cannot be attributed solely to readback removal.

These measurements are from one verify/perf pair. Repeated runs are
needed to establish stable end-to-end performance. Mean forward timing
includes the first forward; the reported generation throughput uses a
different timing interval.

## Next step

Implement resident Q/K/V weights in shared DDR and measure the reduction
in repeated W-copy overhead separately. Record one-time weight loading
cost independently from inference timing.