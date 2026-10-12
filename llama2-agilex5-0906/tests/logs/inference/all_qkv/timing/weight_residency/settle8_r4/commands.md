# Build and Board Test Commands

本文件记录 settle=8 实验的软件构建和板上复现命令。

- 硬件运行参数：`OVERLAP_MUL_ADD=1`、`FP32_SETTLE_CYCLES=8`
- 软件运行模式：`verify|perf` + `resident`
- OpenMP 线程数：1
- 模型：`stories15M.bin`
- Tokenizer：`tokenizer.bin`

## 1. Record Scope

本次原始日志名为 `settle4_*`，但两份日志中的 CSR 读回均为：

```text
FP32_SETTLE_CYCLES=8 expected_settle=8
```

归档文件因此命名为 `settle8_*_r4`，原始日志内容不变。

以下为整理后的复现命令，不是本次运行的终端历史记录。
`run_fpga_resident_settle8` 是建议用于复现的可执行文件名。

归档已有结果不需要重新运行这些命令。若执行复现，请使用新日志名，
不要覆盖本目录中已经保存的 r4 日志。

## 2. Software Build — Development Host

工作目录：开发机工程的 `sw/`。

使用与板上 AArch64 Linux 兼容的交叉编译工具链：

```bash
aarch64-linux-gnu-gcc -O2 -Wall -Wextra -std=gnu11 \
    -D_FILE_OFFSET_BITS=64 \
    -fno-fast-math \
    -ffp-contract=off \
    -fopenmp \
    -o run_fpga_resident_settle8 \
    run_fpga.c \
    accel/gemv_accel.c \
    -lm
```

如果实际工具链前缀不同，应替换编译器名称。
如果在 AArch64 Linux 环境原生编译，使用相同参数，将编译器替换为 `gcc`。

必须保留：

```text
-fno-fast-math
-ffp-contract=off
```

编译前确认驱动的预期 BUILD_ID 和 `expected_settle` 与待测试映像一致。
本实验的驱动预期等待参数为：

```c
const uint32_t expected_settle = UINT32_C(8);
```

编译完成后，只需将可执行文件部署到板上；无需部署整个源码工程。

## 3. Board Test Preconditions

板上工作目录中应包含：

```text
run_fpga_resident_settle8
stories15M.bin
tokenizer.bin
```

运行要求：

- 已加载对应的 settle=8 硬件映像。
- 保留 `mem=896M` 启动参数。
- 不并发运行其他 FPGA、共享 DDR 测试或重配置操作。
- 先运行 verify；成功后再运行 perf。
- 本次归档日志中 `GEMV_CLOCK_HZ` 未设置。
- 超时或异常退出不等于取消 FPGA AXI 事务，不自动 CLEAR 或重试。

## 4. Verify — Resident Weights, 2 Steps

以下命令在板上 Bash 中执行。
使用新的复现日志目录，不覆盖已有归档：

```bash
log_dir="$(mktemp -d ./settle8_retest_XXXXXX)"
printf 'Log directory: %s\n' "$log_dir"
```

运行短推理：

```bash
if sudo env -u GEMV_CLOCK_HZ \
    GEMV_MODE=verify GEMV_WEIGHTS=resident OMP_NUM_THREADS=1 \
    ./run_fpga_resident_settle8 stories15M.bin \
    -z tokenizer.bin -m generate -t 0 -s 1 -n 2 \
    -i "Once upon a time" \
    > "$log_dir/settle8_verify_n2.stdout.txt" \
    2> "$log_dir/settle8_verify_n2.log"
then
    run_rc=0
else
    run_rc=$?
fi

printf 'exit_status=%s\n' "$run_rc" \
    >> "$log_dir/settle8_verify_n2.log"

test "$run_rc" -eq 0 || exit "$run_rc"
```

验收要求：

```text
FP32_SETTLE_CYCLES=8 expected_settle=8
initial_readback=PASS
forward_calls=2
Wq/Wk/Wv 各 12 次
qkv_calls=36
全部 36 条比较均为 288/288 bit-exact
exit_status=0
```

## 5. Performance — Resident Weights, 32 Steps

确认 verify 通过后，在同一 Bash 会话中执行：

```bash
if sudo env -u GEMV_CLOCK_HZ \
    GEMV_MODE=perf GEMV_WEIGHTS=resident OMP_NUM_THREADS=1 \
    ./run_fpga_resident_settle8 stories15M.bin \
    -z tokenizer.bin -m generate -t 0 -s 1 -n 32 \
    -i "Once upon a time" \
    > "$log_dir/settle8_perf_n32.stdout.txt" \
    2> "$log_dir/settle8_perf_n32.log"
then
    run_rc=0
else
    run_rc=$?
fi

printf 'exit_status=%s\n' "$run_rc" \
    >> "$log_dir/settle8_perf_n32.log"

test "$run_rc" -eq 0 || exit "$run_rc"
```

验收要求：

```text
FP32_SETTLE_CYCLES=8 expected_settle=8
initial_readback=PASS
forward_calls=32
Wq/Wk/Wv 各 192 次
qkv_calls=576
全部 576 条比较均为 288/288 bit-exact
exit_status=0
```

`perf` 模式仍保留 CPU 参考计算和逐位比较，
只关闭每次 GEMV 前后的 W/x 全量读回。

性能结果及与 settle=16 基线的比较见 `result.md`。