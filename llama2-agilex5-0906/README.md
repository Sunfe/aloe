# llama2.c on Agilex 5E (DE25-Standard)

## 仿真 (无需板子)
cd hw/scripts && ./sim.sh tb_pe_array && ./sim.sh tb_w_reader && ./sim.sh tb_matvec_top

## 硬件
1. IP Catalog 生成 fp32_mul_ip (MULT, latency 3, 带 en) 与 fp32_add_ip (ADD, latency 4, 带 en) 到 hw/ip/
2. Platform Designer: 打开 hw/qsys/de25_llama.qsys (从 GHRD 复制), 添加 matvec_top, 连线见 docs/01_architecture.md §5.1
3. hw/scripts/build.sh && hw/scripts/gen_rbf.sh, core.rbf 拷到板子 /lib/firmware/

## 板子
1. reserved-memory: linux/boot/uboot_reserve.txt (或合并 linux/dts/reserved-memory.dtsi)
2. 加载 overlay linux/dts/de25_llama.dtso
3. cd sw && make CROSS=aarch64-linux-gnu-  →  拷 run_accel / accel_selftest / *.bin 到板子
4. tests/test_matvec_unit.sh  →  tests/test_e2e.sh

## To Do List
[PASS] 固定 4×4 GEMV
[PASS] DDR 双向交换
[PASS] 独立 FP32 运算测试
[PASS] 可变尺寸 GEMV 基础测试：15 项
[TODO] 可变尺寸 GEMV 扩展尺寸测试
[TODO] 非法参数及错误后恢复测试
[TODO] 真实模型矩阵验证
[TODO] 接入 run.c