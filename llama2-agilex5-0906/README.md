# llama2.c on Agilex 5E (DE25-Standard)

## 1.仿真 (无需板子)
cd hw/scripts && ./sim.sh tb_pe_array && ./sim.sh tb_w_reader && ./sim.sh tb_matvec_top

## 2.硬件
1. IP Catalog 生成 fp32_mul_ip (MULT, latency 3, 带 en) 与 fp32_add_ip (ADD, latency 4, 带 en) 到 hw/ip/
2. Platform Designer: 打开 hw/qsys/de25_llama.qsys (从 GHRD 复制), 添加 matvec_top, 连线见 docs/01_architecture.md §5.1
3. hw/scripts/build.sh && hw/scripts/gen_rbf.sh, core.rbf 拷到板子 /lib/firmware/

## 3.板子
1. reserved-memory: linux/boot/uboot_reserve.txt (或合并 linux/dts/reserved-memory.dtsi)
2. 加载 overlay linux/dts/de25_llama.dtso
3. cd sw && make CROSS=aarch64-linux-gnu-  →  拷 run_accel / accel_selftest / *.bin 到板子
4. tests/test_matvec_unit.sh  →  tests/test_e2e.sh



##  4.TODO

[PASS] 全部 6 层 Q/K/V 接入 FPGA
[PASS] GEMV_MODE=verify|perf
[PASS] GEMV_WEIGHTS=copy|resident
[PASS] 18 个 Q/K/V 权重矩阵常驻共享 DDR
[PASS] 权重常驻重复减少约 167 ms/forward 的主机复制开销
[PASS] 根据实际可变 GEMV RTL 解释周期主要组成
[PASS] 实施组内乘法、加法重叠调度
[PASS] 增加 GVM2 VERSION 和 128-bit BUILD_ID
[PASS] 板上 BUILD_ID 与指定构建清单匹配
[PASS] 板上确认 OVERLAP_MUL_ADD=1、FP32_SETTLE_CYCLES=16
[PASS] 当前构建 verify+resident，2 步短推理
[PASS] 当前构建 perf+resident，32 步性能测试
[PASS] 两次合计 612 次 GEMV、176,256 个输出元素逐位一致
[PASS] GEMV 平均周期从约 369 万降至约 256 万
[PASS] 周期下降约 30.51%，符合调度推导
[TODO] 将 BUILD_ID 检查正式接入 C 驱动，并确认编译及板上运行
[TODO] 完善构建输入快照、依赖清单与 SOF 哈希的对应关系
[TODO] 保存并核对本次 Quartus 编译、时序、独立 GEMV 回归记录
[TODO] 确认实际 GEMV 时钟频率
[TODO] 同条件独立纯 CPU 推理基准
[TODO] 后续硬件效率优化及更大矩阵接入范围