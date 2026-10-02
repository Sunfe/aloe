



```
terasic@localhost:~$ sudo env GEMV_MODE=perf GEMV_WEIGHTS=copy OMP_NUM_THREADS=1 \
    ./run_fpga_resident stories15M.bin \perf GEMV_WEIGHTS=copy OMP_NUM_THREADS=1 \
    -z tokenizer.bin \t stories15M.bin \
    -m generate \bin \
    -t 0 -s 1 -n 32 \
    -i "Once upon a time" \
    > perf_copy_n32.stdout.txt 2> perf_copy_n32.log &&
sudo env GEMV_MODE=perf GEMV_WEIGHTS=resident OMP_NUM_THREADS=1 \
    ./run_fpga_resident stories15M.bin \ident OMP_NUM_THREADS=1 \
    -z tokenizer.bin \t stories15M.bin \
    -m generate \bin \
    -t 0 -s 1 -n 32 \
    -i "Once upon a time" \
    > perf_resident_n32.stdout.txt 2> perf_resident_n32.log
    > perf_resident_n32.stdout.txt 2> perf_resident_n32.log
terasic@localhost:~$ 
terasic@localhost:~$ 
terasic@localhost:~$ 
terasic@localhost:~$ cmp perf_copy_n32.stdout.txt perf_resident_n32.stdout.txt
terasic@localhost:~$ tail -n 35 perf_copy_n32.log perf_resident_n32.log
==> perf_copy_n32.log <==
Wv verify: pos=31 token=263 layer=3 288/288 bit-exact
Wq verify: pos=31 token=263 layer=4 288/288 bit-exact
Wk verify: pos=31 token=263 layer=4 288/288 bit-exact
Wv verify: pos=31 token=263 layer=4 288/288 bit-exact
Wq verify: pos=31 token=263 layer=5 288/288 bit-exact
Wk verify: pos=31 token=263 layer=5 288/288 bit-exact
Wv verify: pos=31 token=263 layer=5 288/288 bit-exact
achieved tok/s: 1.127437

[TIMING] forward_calls=32 forward_total_ms=28540.878 forward_mean_ms=891.902
[TIMING] Wq calls=192 cpu_ref_ms=57.969 accel_api_ms=8946.510 compare_ms=0.508 log_ms=9.890 cycles_mean=3686076.7 cycles_max=3689730
[TIMING] Wk calls=192 cpu_ref_ms=59.348 accel_api_ms=8946.020 compare_ms=0.487 log_ms=6.669 cycles_mean=3685876.3 cycles_max=3687600
[TIMING] Wv calls=192 cpu_ref_ms=58.291 accel_api_ms=8945.612 compare_ms=0.471 log_ms=6.452 cycles_mean=3685927.4 cycles_max=3695649
[TIMING] qkv_calls=576
[TIMING] qkv_cpu_reference      total_ms=   175.607 per_forward_ms=    5.488 forward_pct=  0.62
[TIMING] qkv_accel_api          total_ms= 26838.142 per_forward_ms=  838.692 forward_pct= 94.03
[TIMING] qkv_result_compare     total_ms=     1.466 per_forward_ms=    0.046 forward_pct=  0.01
[TIMING] qkv_verify_log         total_ms=    23.012 per_forward_ms=    0.719 forward_pct=  0.08
[TIMING] qkv_helper_other       total_ms=     0.517 per_forward_ms=    0.016 forward_pct=  0.00
[TIMING] remaining_forward      total_ms=  1502.133 per_forward_ms=   46.942 forward_pct=  5.26
[TIMING] The following stages are INSIDE qkv_accel_api;
[TIMING] do not add them to qkv_accel_api again.
[TIMING] accel_preflight        total_ms=     1.340 per_forward_ms=    0.042 forward_pct=  0.00
[TIMING] buffer_prepare         total_ms=    25.075 per_forward_ms=    0.784 forward_pct=  0.09
[TIMING] W_copy_to_DDR          total_ms=  5339.973 per_forward_ms=  166.874 forward_pct= 18.71
[TIMING] X_copy_to_DDR          total_ms=    18.789 per_forward_ms=    0.587 forward_pct=  0.07
[TIMING] input_precheck         total_ms=    75.264 per_forward_ms=    2.352 forward_pct=  0.26
[TIMING] CSR_configuration      total_ms=     6.855 per_forward_ms=    0.214 forward_pct=  0.02
[TIMING] START_to_DONE          total_ms= 21292.088 per_forward_ms=  665.378 forward_pct= 74.60
[TIMING] completion_check       total_ms=     0.832 per_forward_ms=    0.026 forward_pct=  0.00
[TIMING] input_postcheck        total_ms=    19.254 per_forward_ms=    0.602 forward_pct=  0.07
[TIMING] Y_copy_to_CPU          total_ms=    58.222 per_forward_ms=    1.819 forward_pct=  0.20
[TIMING] accel_api_other        total_ms=     0.451 per_forward_ms=    0.014 forward_pct=  0.00
[TIMING] FPGA cycles_sum=2123113042
[TIMING] GEMV_CLOCK_HZ unset: FPGA time remains in cycles.

==> perf_resident_n32.log <==
Wv verify: pos=31 token=263 layer=3 288/288 bit-exact
Wq verify: pos=31 token=263 layer=4 288/288 bit-exact
Wk verify: pos=31 token=263 layer=4 288/288 bit-exact
Wv verify: pos=31 token=263 layer=4 288/288 bit-exact
Wq verify: pos=31 token=263 layer=5 288/288 bit-exact
Wk verify: pos=31 token=263 layer=5 288/288 bit-exact
Wv verify: pos=31 token=263 layer=5 288/288 bit-exact
achieved tok/s: 1.300990

[TIMING] forward_calls=32 forward_total_ms=24708.918 forward_mean_ms=772.154
[TIMING] Wq calls=192 cpu_ref_ms=100.002 accel_api_ms=7165.323 compare_ms=0.747 log_ms=14.653 cycles_mean=3686146.6 cycles_max=3688737
[TIMING] Wk calls=192 cpu_ref_ms=98.814 accel_api_ms=7165.178 compare_ms=0.729 log_ms=9.505 cycles_mean=3686028.4 cycles_max=3697834
[TIMING] Wv calls=192 cpu_ref_ms=99.274 accel_api_ms=7165.185 compare_ms=0.712 log_ms=7.232 cycles_mean=3685879.7 cycles_max=3687766
[TIMING] qkv_calls=576
[TIMING] qkv_cpu_reference      total_ms=   298.089 per_forward_ms=    9.315 forward_pct=  1.21
[TIMING] qkv_accel_api          total_ms= 21495.686 per_forward_ms=  671.740 forward_pct= 87.00
[TIMING] qkv_result_compare     total_ms=     2.189 per_forward_ms=    0.068 forward_pct=  0.01
[TIMING] qkv_verify_log         total_ms=    31.389 per_forward_ms=    0.981 forward_pct=  0.13
[TIMING] qkv_helper_other       total_ms=     0.654 per_forward_ms=    0.020 forward_pct=  0.00
[TIMING] remaining_forward      total_ms=  2880.911 per_forward_ms=   90.028 forward_pct= 11.66
[TIMING] The following stages are INSIDE qkv_accel_api;
[TIMING] do not add them to qkv_accel_api again.
[TIMING] accel_preflight        total_ms=     1.767 per_forward_ms=    0.055 forward_pct=  0.01
[TIMING] buffer_prepare         total_ms=    23.590 per_forward_ms=    0.737 forward_pct=  0.10
[TIMING] W_copy_to_DDR          total_ms=     0.131 per_forward_ms=    0.004 forward_pct=  0.00
[TIMING] X_copy_to_DDR          total_ms=    19.304 per_forward_ms=    0.603 forward_pct=  0.08
[TIMING] input_precheck         total_ms=    75.276 per_forward_ms=    2.352 forward_pct=  0.30
[TIMING] CSR_configuration      total_ms=     6.973 per_forward_ms=    0.218 forward_pct=  0.03
[TIMING] START_to_DONE          total_ms= 21289.572 per_forward_ms=  665.299 forward_pct= 86.16
[TIMING] completion_check       total_ms=     0.856 per_forward_ms=    0.027 forward_pct=  0.00
[TIMING] input_postcheck        total_ms=    19.069 per_forward_ms=    0.596 forward_pct=  0.08
[TIMING] Y_copy_to_CPU          total_ms=    58.652 per_forward_ms=    1.833 forward_pct=  0.24
[TIMING] accel_api_other        total_ms=     0.497 per_forward_ms=    0.016 forward_pct=  0.00
[TIMING] FPGA cycles_sum=2123146500
[TIMING] GEMV_CLOCK_HZ unset: FPGA time remains in cycles.
```
## First 32-step weight residency performance comparison

Both runs used `run_fpga_resident`, `stories15M.bin`,
`GEMV_MODE=perf`, and `OMP_NUM_THREADS=1`.

Generation parameters:

```text
-m generate -t 0 -s 1 -n 32 -i "Once upon a time"
```

Only `GEMV_WEIGHTS` changed between `copy` and `resident`.

### Validation

- Both runs completed 32 forward passes and 576 Q/K/V GEMV calls.
- All Q/K/V outputs passed bit-exact CPU comparisons.
- Generated stdout files matched.

### Measurements

| Metric                              |       Copy |   Resident |
| ----------------------------------- | ---------: | ---------: |
| Reported tokens/s                   |   1.127437 |   1.300990 |
| Mean forward time, ms               |    891.902 |    772.154 |
| Accelerator API per forward, ms     |    838.692 |    671.740 |
| W upload per forward, ms            |    166.874 |      0.004 |
| START-to-DONE per forward, ms       |    665.378 |    665.299 |
| CPU Q/K/V reference per forward, ms |      5.488 |      9.315 |
| Remaining forward per forward, ms   |     46.942 |     90.028 |
| FPGA total cycles                   | 2123113042 | 2123146500 |

### Interpretation

Resident weights removed approximately 166.870 ms of W upload time
per forward. The accelerator API reduction was 166.952 ms per forward,
closely matching the eliminated upload cost.

Reported generation throughput increased by approximately 15.4%.
Mean forward time decreased by approximately 13.4%.

FPGA execution time and cycle counts remained nearly unchanged.
The FPGA still reads weights from shared DDR for every GEMV.

CPU reference and remaining-forward times were higher in the resident
run, reducing the observed end-to-end benefit. The cause is not
established by this single pair of measurements.

These are first-pair measurements, not a repeated-run average.
One-time resident loading is excluded from forward and generation
timing and must be reported separately from the resident startup log.



**这次已经测到了权重常驻的实际收益：生成速度从 `1.127437 tok/s` 提高到 `1.300990 tok/s`，提升约 15.4%。重复复制 W 的开销基本消除，结果验证也通过了。**

这可以保存为“权重常驻功能通过，并完成首组性能对照”的基线。

两次运行都完成了：

```text
32 次前向 × 6 层 × 每层 3 次 Q/K/V = 576 次 GEMV
```

两份日志均正常进入最终计时汇总。按照当前程序的失败退出逻辑，说明这些调用的 CPU/FPGA 逐位比较全部通过。`cmp` 没有输出，也与生成文本一致相符。

**性能变化与本次修改的目标吻合。**

以下时间统一为每次前向的平均耗时：

| 指标                |    perf + copy | perf + resident | 变化            |
| ------------------- | -------------: | --------------: | --------------- |
| 生成速度            | 1.127437 tok/s |  1.300990 tok/s | **提高 15.4%**  |
| 完整前向            |     891.902 ms |      772.154 ms | **减少 13.4%**  |
| 加速器 API          |     838.692 ms |      671.740 ms | 减少 166.952 ms |
| W 复制到 DDR        |     166.874 ms |        0.004 ms | **基本消除**    |
| START 到观察到 DONE |     665.378 ms |      665.299 ms | 基本相同        |
| 输入前检查          |       2.352 ms |        2.352 ms | 相同            |
| 输入后检查          |       0.602 ms |        0.596 ms | 基本相同        |
| CPU Q/K/V 参考计算  |       5.488 ms |        9.315 ms | 增加 3.827 ms   |
| 其余前向计算        |      46.942 ms |       90.028 ms | 增加 43.086 ms  |

其中最关键的对应关系是：

```text
W 复制减少：
166.874 - 0.004 = 166.870 ms / forward

加速器 API 减少：
838.692 - 671.740 = 166.952 ms / forward
```

两者几乎完全一致。**这说明驱动的收益可以明确归因于减少重复权重复制。**

FPGA 总周期也基本相同：

```text
copy：     2,123,113,042 cycles
resident： 2,123,146,500 cycles

差异约 0.0016%
```

权重仍然位于共享 DDR，FPGA 每次仍需读取并计算，因此硬件周期没有明显下降是预期行为。

**完整推理的收益低于驱动收益，是因为其他 CPU 阶段在这次 resident 运行中变慢了。**

本次：

```text
加速器 API 节省约：166.952 ms / forward
完整前向实际节省：119.748 ms / forward

差额约：47.204 ms / forward
```

这部分主要由表中的 CPU 参考计算和其余前向计算增加解释。具体是 CPU 频率、调度、缓存还是其他运行状态导致，当前汇总无法确定，不能直接认定是权重常驻引起的退化。

所以这组数据应记录为：

> 权重常驻使加速器 API 每次前向减少约 167 ms；本组对照的生成吞吐率提高约 15.4%。CPU 其他阶段存在运行间差异，稳定收益仍需重复测量。

另外，当前 `tok/s` 不包含程序启动时的一次性权重加载。归档时应记录**本次 resident 日志开头的 `load_ms`**，不要沿用前面短验证的 `676.349 ms`。

**日志继续放在你已经确定的目录里。**

```text
tests/logs/inference/all_qkv/timing/weight_residency/
├── resident_verify_n2.log
├── resident_verify_n2.stdout.txt
├── copy_perf_n32.log
├── copy_perf_n32.stdout.txt
├── resident_perf_n32.log
├── resident_perf_n32.stdout.txt
├── README.md
└── result.md
```

本次四个文件的对应关系为：

| 板上文件名                     | 归档文件名                     |
| ------------------------------ | ------------------------------ |
| `perf_copy_n32.log`            | `copy_perf_n32.log`            |
| `perf_copy_n32.stdout.txt`     | `copy_perf_n32.stdout.txt`     |
| `perf_resident_n32.log`        | `resident_perf_n32.log`        |
| `perf_resident_n32.stdout.txt` | `resident_perf_n32.stdout.txt` |

你贴出的命令显示存在重复片段，但后面的两份计时日志是完整的。归档前，在板上补看启动配置，确认保存的是本次两个模式的日志：

```bash
head -n 8 perf_copy_n32.log perf_resident_n32.log
```

应分别显示：

```text
input_readback=perf weights=copy
input_readback=perf weights=resident
```

将四个原始文件传到电脑后，按上表放入已有目录即可。保留完整日志，不只保存 `tail` 的截取内容。

可以在已有 `result.md` 后面追加下面这段英文记录：

````markdown
## First 32-step weight residency performance comparison

Both runs used `run_fpga_resident`, `stories15M.bin`,
`GEMV_MODE=perf`, and `OMP_NUM_THREADS=1`.

Generation parameters:

```text
-m generate -t 0 -s 1 -n 32 -i "Once upon a time"
```

Only `GEMV_WEIGHTS` changed between `copy` and `resident`.

### Validation

- Both runs completed 32 forward passes and 576 Q/K/V GEMV calls.
- All Q/K/V outputs passed bit-exact CPU comparisons.
- Generated stdout files matched.

### Measurements

| Metric | Copy | Resident |
|---|---:|---:|
| Reported tokens/s | 1.127437 | 1.300990 |
| Mean forward time, ms | 891.902 | 772.154 |
| Accelerator API per forward, ms | 838.692 | 671.740 |
| W upload per forward, ms | 166.874 | 0.004 |
| START-to-DONE per forward, ms | 665.378 | 665.299 |
| CPU Q/K/V reference per forward, ms | 5.488 | 9.315 |
| Remaining forward per forward, ms | 46.942 | 90.028 |
| FPGA total cycles | 2123113042 | 2123146500 |

### Interpretation

Resident weights removed approximately 166.870 ms of W upload time
per forward. The accelerator API reduction was 166.952 ms per forward,
closely matching the eliminated upload cost.

Reported generation throughput increased by approximately 15.4%.
Mean forward time decreased by approximately 13.4%.

FPGA execution time and cycle counts remained nearly unchanged.
The FPGA still reads weights from shared DDR for every GEMV.

CPU reference and remaining-forward times were higher in the resident
run, reducing the observed end-to-end benefit. The cause is not
established by this single pair of measurements.

These are first-pair measurements, not a repeated-run average.
One-time resident loading is excluded from forward and generation
timing and must be reported separately from the resident startup log.
````

如果上一次源码基线已经提交，本次只提交日志和文档，可以使用这个英文 commit message：

```text
test(gemv): record 32-step resident weight performance comparison

Archive copy and resident QKV inference logs with input readback
disabled and one CPU thread.

Both runs completed 32 forward passes and 576 bit-exact QKV checks,
with matching generated output.

Resident weights reduced W upload time from 166.874 to 0.004 ms
per forward. Reported throughput increased from 1.127437 to
1.300990 tokens/s, while FPGA execution time remained unchanged.

Document CPU timing variation and keep one-time weight loading
separate from inference timing.
```

**下一步的重点可以转向 FPGA 执行路径。** 当前常驻模式中：

```text
完整前向：       772.154 ms
START_to_DONE：  665.299 ms，占 86.16%
```

整个加速器 API 中，除去 `START_to_DONE`，其他阶段合计只有约 `6.441 ms/forward`。继续削减这些驱动步骤，收益已经比较有限。

先用相同参数反向再跑一组 `resident → copy`，保存为带 `_r2` 后缀的新日志，确认收益可重复。随后需要查看**当前实际使用、CSR 为 `0x20023000` 的可变尺寸 GEMV RTL、FP32 运算封装以及实际时钟配置**，判断等待主要来自串行浮点计算还是 DDR 访问。基于那份硬件实现，再选择下一项单独优化。



-------

```
terasic@localhost:~$ run_case()
{
    local weights="$1"
    local prefix="$2"
    if [[ -e "$prefix.log" || -e "$prefix.stdout.txt" ]]; then
        printf 'Refusing to overwrite existing files: %s\n' "$prefix" >&2
        return 1
    fi
    sudo env \
        GEMV_MODE=perf \
        GEMV_WEIGHTS="$weights" \
        OMP_NUM_THREADS=1 \
        ./run_fpga_resident stories15M.bin \
        -z tokenizer.bin \
        -m generate \
        -t 0 -s 1 -n 32 \
        -i "Once upon a time" \
        > "$prefix.stdout.txt" 2> "$prefix.log"
}
run_case resident perf_resident_n32_r2 &&
run_case copy perf_copy_n32_r2 &&
cmp perf_copy_n32_r2.stdout.txt perf_resident_n32_r2.stdout.txt
[sudo] password for terasic: 

terasic@localhost:~$ head -n 8 perf_resident_n32_r2.log perf_copy_n32_r2.log
==> perf_resident_n32_r2.log <==
Model config: dim=288 layers=6 heads=6 kv_heads=6
Q/K/V shapes: each 288 x 288; enabling all layers
GEMV mode: input_readback=perf weights=resident
GEMV ready: CSR=0x20023000, dim=288, mode=perf, full_input_readback=off
GEMV checks: guards=on, output_poison=on, CSR_readback=on, completion=on; W_copy=initial_load_only
[WEIGHTS] mode=resident matrices=18 payload_bytes=5971968 pool_bytes=5974272 load_ms=765.265 initial_readback=PASS
Wq verify: pos=0 token=1 layer=0 288/288 bit-exact
Wk verify: pos=0 token=1 layer=0 288/288 bit-exact

==> perf_copy_n32_r2.log <==
Model config: dim=288 layers=6 heads=6 kv_heads=6
Q/K/V shapes: each 288 x 288; enabling all layers
GEMV mode: input_readback=perf weights=copy
GEMV ready: CSR=0x20023000, dim=288, mode=perf, full_input_readback=off
GEMV checks: guards=on, output_poison=on, CSR_readback=on, completion=on; W_copy=every_call
[WEIGHTS] mode=copy matrices=18 W_copy=every_call
Wq verify: pos=0 token=1 layer=0 288/288 bit-exact
Wk verify: pos=0 token=1 layer=0 288/288 bit-exact
terasic@localhost:~$ tail -n 35 perf_resident_n32_r2.log perf_copy_n32_r2.log
==> perf_resident_n32_r2.log <==
Wv verify: pos=31 token=263 layer=3 288/288 bit-exact
Wq verify: pos=31 token=263 layer=4 288/288 bit-exact
Wk verify: pos=31 token=263 layer=4 288/288 bit-exact
Wv verify: pos=31 token=263 layer=4 288/288 bit-exact
Wq verify: pos=31 token=263 layer=5 288/288 bit-exact
Wk verify: pos=31 token=263 layer=5 288/288 bit-exact
Wv verify: pos=31 token=263 layer=5 288/288 bit-exact
achieved tok/s: 1.369560

[TIMING] forward_calls=32 forward_total_ms=25655.515 forward_mean_ms=801.735
[TIMING] Wq calls=192 cpu_ref_ms=61.041 accel_api_ms=7164.321 compare_ms=0.489 log_ms=8.576 cycles_mean=3686730.4 cycles_max=3696286
[TIMING] Wk calls=192 cpu_ref_ms=62.725 accel_api_ms=7165.330 compare_ms=0.502 log_ms=26.844 cycles_mean=3686474.2 cycles_max=3689304
[TIMING] Wv calls=192 cpu_ref_ms=60.214 accel_api_ms=7166.978 compare_ms=0.476 log_ms=5.100 cycles_mean=3686442.6 cycles_max=3688914
[TIMING] qkv_calls=576
[TIMING] qkv_cpu_reference      total_ms=   183.980 per_forward_ms=    5.749 forward_pct=  0.72
[TIMING] qkv_accel_api          total_ms= 21496.629 per_forward_ms=  671.770 forward_pct= 83.79
[TIMING] qkv_result_compare     total_ms=     1.467 per_forward_ms=    0.046 forward_pct=  0.01
[TIMING] qkv_verify_log         total_ms=    40.520 per_forward_ms=    1.266 forward_pct=  0.16
[TIMING] qkv_helper_other       total_ms=     0.412 per_forward_ms=    0.013 forward_pct=  0.00
[TIMING] remaining_forward      total_ms=  3932.506 per_forward_ms=  122.891 forward_pct= 15.33
[TIMING] The following stages are INSIDE qkv_accel_api;
[TIMING] do not add them to qkv_accel_api again.
[TIMING] accel_preflight        total_ms=     1.389 per_forward_ms=    0.043 forward_pct=  0.01
[TIMING] buffer_prepare         total_ms=    23.183 per_forward_ms=    0.724 forward_pct=  0.09
[TIMING] W_copy_to_DDR          total_ms=     0.096 per_forward_ms=    0.003 forward_pct=  0.00
[TIMING] X_copy_to_DDR          total_ms=    18.934 per_forward_ms=    0.592 forward_pct=  0.07
[TIMING] input_precheck         total_ms=    75.554 per_forward_ms=    2.361 forward_pct=  0.29
[TIMING] CSR_configuration      total_ms=     6.851 per_forward_ms=    0.214 forward_pct=  0.03
[TIMING] START_to_DONE          total_ms= 21292.403 per_forward_ms=  665.388 forward_pct= 82.99
[TIMING] completion_check       total_ms=     0.839 per_forward_ms=    0.026 forward_pct=  0.00
[TIMING] input_postcheck        total_ms=    19.058 per_forward_ms=    0.596 forward_pct=  0.07
[TIMING] Y_copy_to_CPU          total_ms=    57.917 per_forward_ms=    1.810 forward_pct=  0.23
[TIMING] accel_api_other        total_ms=     0.405 per_forward_ms=    0.013 forward_pct=  0.00
[TIMING] FPGA cycles_sum=2123452270
[TIMING] GEMV_CLOCK_HZ unset: FPGA time remains in cycles.

==> perf_copy_n32_r2.log <==
Wv verify: pos=31 token=263 layer=3 288/288 bit-exact
Wq verify: pos=31 token=263 layer=4 288/288 bit-exact
Wk verify: pos=31 token=263 layer=4 288/288 bit-exact
Wv verify: pos=31 token=263 layer=4 288/288 bit-exact
Wq verify: pos=31 token=263 layer=5 288/288 bit-exact
Wk verify: pos=31 token=263 layer=5 288/288 bit-exact
Wv verify: pos=31 token=263 layer=5 288/288 bit-exact
achieved tok/s: 1.114907

[TIMING] forward_calls=32 forward_total_ms=28848.450 forward_mean_ms=901.514
[TIMING] Wq calls=192 cpu_ref_ms=68.801 accel_api_ms=8947.592 compare_ms=0.590 log_ms=11.247 cycles_mean=3686561.1 cycles_max=3688138
[TIMING] Wk calls=192 cpu_ref_ms=71.354 accel_api_ms=8946.565 compare_ms=0.562 log_ms=8.415 cycles_mean=3686445.7 cycles_max=3688036
[TIMING] Wv calls=192 cpu_ref_ms=69.328 accel_api_ms=8947.793 compare_ms=0.543 log_ms=7.917 cycles_mean=3686430.9 cycles_max=3687860
[TIMING] qkv_calls=576
[TIMING] qkv_cpu_reference      total_ms=   209.484 per_forward_ms=    6.546 forward_pct=  0.73
[TIMING] qkv_accel_api          total_ms= 26841.951 per_forward_ms=  838.811 forward_pct= 93.04
[TIMING] qkv_result_compare     total_ms=     1.695 per_forward_ms=    0.053 forward_pct=  0.01
[TIMING] qkv_verify_log         total_ms=    27.580 per_forward_ms=    0.862 forward_pct=  0.10
[TIMING] qkv_helper_other       total_ms=     0.648 per_forward_ms=    0.020 forward_pct=  0.00
[TIMING] remaining_forward      total_ms=  1767.093 per_forward_ms=   55.222 forward_pct=  6.13
[TIMING] The following stages are INSIDE qkv_accel_api;
[TIMING] do not add them to qkv_accel_api again.
[TIMING] accel_preflight        total_ms=     1.458 per_forward_ms=    0.046 forward_pct=  0.01
[TIMING] buffer_prepare         total_ms=    25.132 per_forward_ms=    0.785 forward_pct=  0.09
[TIMING] W_copy_to_DDR          total_ms=  5342.388 per_forward_ms=  166.950 forward_pct= 18.52
[TIMING] X_copy_to_DDR          total_ms=    18.863 per_forward_ms=    0.589 forward_pct=  0.07
[TIMING] input_precheck         total_ms=    74.892 per_forward_ms=    2.340 forward_pct=  0.26
[TIMING] CSR_configuration      total_ms=     6.867 per_forward_ms=    0.215 forward_pct=  0.02
[TIMING] START_to_DONE          total_ms= 21293.873 per_forward_ms=  665.434 forward_pct= 73.81
[TIMING] completion_check       total_ms=     0.836 per_forward_ms=    0.026 forward_pct=  0.00
[TIMING] input_postcheck        total_ms=    19.216 per_forward_ms=    0.600 forward_pct=  0.07
[TIMING] Y_copy_to_CPU          total_ms=    57.900 per_forward_ms=    1.809 forward_pct=  0.20
[TIMING] accel_api_other        total_ms=     0.526 per_forward_ms=    0.016 forward_pct=  0.00
[TIMING] FPGA cycles_sum=2123412052
[TIMING] GEMV_CLOCK_HZ unset: FPGA time remains in cycles.
```



## Reverse-order repeat

Execution order: resident, then copy.

Both runs used GEMV_MODE=perf, OMP_NUM_THREADS=1, and 32 requested
steps. Each completed 32 forward passes and 576 bit-exact Q/K/V
checks. The generated stdout files matched.

| Metric                          |       Copy |   Resident |
| ------------------------------- | ---------: | ---------: |
| Reported tokens/s               |   1.114907 |   1.369560 |
| Mean forward time, ms           |    901.514 |    801.735 |
| Accelerator API per forward, ms |    838.811 |    671.770 |
| W upload per forward, ms        |    166.950 |      0.003 |
| START-to-DONE per forward, ms   |    665.434 |    665.388 |
| FPGA total cycles               | 2123412052 | 2123452270 |

Resident initialization and readback passed in 765.265 ms.
This one-time cost is outside the forward and generation timers.

The accelerator API reduction was 167.041 ms per forward, matching
the eliminated W upload cost. Together with the first comparison,
this confirms a repeatable reduction of approximately 167 ms per
forward, independent of execution order.

Reported throughput improved by approximately 22.8% in this repeat.
CPU-side timing still varies between runs. Reported tokens/s excludes
the first iteration, while mean forward time includes it.



第二组结果也支持权重常驻的收益：驱动每次前向仍节省约 167 ms，FPGA 等待时间基本不变。这次 `tok/s` 更高而 `forward_mean_ms` 也更高，需要结合两种计时口径解释；我会把两轮结果一起核对。**第二组复测通过了，权重常驻的收益已经可以重复确认：加速器 API 每次前向稳定减少约 167 ms。当前软件阶段可以保存基线，下一步进入可变尺寸 GEMV 的硬件瓶颈分析。**

这次不需要继续反复跑相同的软件对照了。

**两组结果相互印证。**

第一组执行顺序是 `copy → resident`，第二组是 `resident → copy`。下面的时间均为每次前向的平均毫秒数：

| 指标                   | 第一组 copy | 第一组 resident | 第二组 copy | 第二组 resident |
| ---------------------- | ----------: | --------------: | ----------: | --------------: |
| 生成速度，tok/s        |    1.127437 |        1.300990 |    1.114907 |        1.369560 |
| 完整前向，ms           |     891.902 |         772.154 |     901.514 |         801.735 |
| 加速器 API，ms         |     838.692 |         671.740 |     838.811 |         671.770 |
| W 复制，ms             |     166.874 |           0.004 |     166.950 |           0.003 |
| START 到 DONE，ms      |     665.378 |         665.299 |     665.434 |         665.388 |
| CPU Q/K/V 参考计算，ms |       5.488 |           9.315 |       6.546 |           5.749 |
| 其余前向计算，ms       |      46.942 |          90.028 |      55.222 |         122.891 |

驱动收益非常稳定：

```text
第一组：
    加速器 API 减少 166.952 ms / forward
    W 复制减少       166.870 ms / forward

第二组：
    加速器 API 减少 167.041 ms / forward
    W 复制减少       166.947 ms / forward
```

这说明收益不依赖于“resident 恰好第二个运行”。无论顺序如何，**取消重复 W 复制，都能让加速器 API 每次前向减少约 167 ms。**

正确性方面，两组对照中的四次运行均完成了：

```text
每次运行：
32 次前向 × 6 层 × 3 个 Q/K/V = 576 次 GEMV

四次运行合计：
2304 次 GEMV
```

根据程序遇到结果不匹配就退出的逻辑，这些调用都通过了 CPU/FPGA 逐位比较。两组内的 `cmp` 均未报告差异。

本次还明确确认了：

```text
resident：
    full_input_readback=off
    W_copy=initial_load_only
    初始权重读回 PASS
    初始加载时间 765.265 ms

copy：
    full_input_readback=off
    W_copy=every_call
```

**本次 token 速度提高约 22.8%，但不能把它写成固定加速比例。**

两组的实测吞吐率改善分别为：

```text
第一组：1.127437 → 1.300990 tok/s，约提高 15.4%
第二组：1.114907 → 1.369560 tok/s，约提高 22.8%
```

完整前向耗时则分别降低约 `13.4%` 和 `11.1%`。

这里有一个容易产生疑问的现象：

```text
resident 第一组：
    forward_mean_ms = 772.154
    tok/s           = 1.300990

resident 第二组：
    forward_mean_ms = 801.735
    tok/s           = 1.369560
```

第二组平均前向更慢，报告的 tok/s 却更高，**这不是计时矛盾，而是统计范围不同**：

- `forward_mean_ms` 包含全部 32 次前向，包括第一次。
- `achieved tok/s` 在第一次迭代输出之后才开始计时，主要统计后面 31 次迭代，还包含采样和文本输出。

因此，第一次前向的额外开销可以抬高 `forward_mean_ms`，却不进入 tok/s 的计时区间。当前没有逐次前向记录，还不能精确拆出每次开销。

日志中的 `remaining_forward` 也确实存在明显变化。因此，本阶段应记录两个层次的结论：

> **已重复确认的驱动收益：约 167 ms/forward。**
> **两组端到端实测收益：生成吞吐率分别提高约 15.4% 和 22.8%。**

不要将两次 tok/s 简单平均后当成稳定性能，也不必因为 CPU 阶段仍有波动就否定已经明确的复制优化收益。

**日志归档沿用之前的分类。**

本次四个文件放入：

```text
tests/logs/inference/all_qkv/timing/weight_residency/
```

对应重命名：

| 板上文件                          | 归档名称                          |
| --------------------------------- | --------------------------------- |
| `perf_copy_n32_r2.log`            | `copy_perf_n32_r2.log`            |
| `perf_copy_n32_r2.stdout.txt`     | `copy_perf_n32_r2.stdout.txt`     |
| `perf_resident_n32_r2.log`        | `resident_perf_n32_r2.log`        |
| `perf_resident_n32_r2.stdout.txt` | `resident_perf_n32_r2.stdout.txt` |

在已有 `result.md` 后追加本次结果，保留第一组记录。建议明确写入：

```markdown
## Reverse-order repeat

Execution order: resident, then copy.

Both runs used GEMV_MODE=perf, OMP_NUM_THREADS=1, and 32 requested
steps. Each completed 32 forward passes and 576 bit-exact Q/K/V
checks. The generated stdout files matched.

| Metric | Copy | Resident |
|---|---:|---:|
| Reported tokens/s | 1.114907 | 1.369560 |
| Mean forward time, ms | 901.514 | 801.735 |
| Accelerator API per forward, ms | 838.811 | 671.770 |
| W upload per forward, ms | 166.950 | 0.003 |
| START-to-DONE per forward, ms | 665.434 | 665.388 |
| FPGA total cycles | 2123412052 | 2123452270 |

Resident initialization and readback passed in 765.265 ms.
This one-time cost is outside the forward and generation timers.

The accelerator API reduction was 167.041 ms per forward, matching
the eliminated W upload cost. Together with the first comparison,
this confirms a repeatable reduction of approximately 167 ms per
forward, independent of execution order.

Reported throughput improved by approximately 22.8% in this repeat.
CPU-side timing still varies between runs. Reported tokens/s excludes
the first iteration, while mean forward time includes it.
```

若源码已经提交，本次日志和文档可以单独提交：

```text
test(gemv): confirm resident weight savings in reverse-order repeat

Record a resident-then-copy comparison with 32 forward passes and
576 bit-exact QKV checks per run. Generated outputs match.

Confirm a repeatable accelerator API reduction of approximately
167 ms per forward from eliminating repeated weight uploads.

Document CPU timing variation, timer boundaries, and the separate
765.265 ms resident initialization cost.
```

**下一步实施目标已经很明确：解释约 369 万个 GEMV 周期花在哪里。**

第二组常驻模式的耗时为：

```text
完整前向：                  801.735 ms
其中 START_to_DONE：        665.388 ms，占 82.99%

加速器 API：                671.770 ms
除 START_to_DONE 外的部分：   6.382 ms
```

驱动其他步骤加起来只有约 `6.4 ms/forward`。接下来更值得分析的是约 `665 ms` 的任务执行等待。注意，这仍是软件观察区间，包含提交和轮询延迟；实际硬件时间需要结合周期数及真实时钟判断。

下一轮按以下顺序实施：

1. **读取当前硬件源码。**需要 CSR 为 `0x20023000` 的可变尺寸 GEMV `.sv`、对应 `_hw.tcl`、当前 `fp32_serial.sv`，以及浮点 IP 延迟配置和 GEMV 实际时钟频率。
2. **按状态机梳理每行、每个元素的执行过程。**区分 DDR 请求与等待、乘法等待、加法等待和状态切换。
3. **判断现有信息是否足够。**能够从 RTL 解释周期，就直接确定优化点；无法区分时，再增加少量周期计数器。
4. **只实施一项主要硬件优化。**根据分析结果选择浮点调度、读取预取或 burst 等，不同时修改多个因素。
5. **沿用当前 `perf + resident` 作为软件基准。**先验证结果，再比较 FPGA 周期、`START_to_DONE` 和完整前向耗时。

请接下来提供上述**当前实际使用的可变尺寸 GEMV RTL、浮点封装和时钟配置**。拿到后就可以把下一项优化落实到具体状态和代码；修改仍按你的偏好提供完整文件或自动修改脚本。