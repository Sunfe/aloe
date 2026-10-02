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