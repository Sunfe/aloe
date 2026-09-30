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

### 已完成

- [x] 保留 GHRD 的 HPS、DDR、时钟和复位基线。
- [x] 验证共享 DDR 区域与 HPS/FPGA 双向数据交换。
- [x] 完成独立 FP32 加法、乘法板上验证。
- [x] 完成固定 4×4 FP32 GEMV 验证。
- [x] 完成可变尺寸 FP32 GEMV 基础与扩展尺寸测试。
- [x] 完成最大行数、最大列数的独立边界测试。
- [x] 完成非法参数拒绝及错误后恢复测试。
- [x] 完成 stories15M 第一层真实 Q 投影验证。
- [x] 接入第一层 Wq，完成逐位比较和生成文本对照。
- [x] 接入全部 6 层 Wq，完成 96 次逐位比较。
- [x] 接入全部 6 层 Q/K/V，完成 288 次逐位比较。
- [x] 增加软件分项计时和 FPGA 周期统计。
- [x] 验证计时版本：16 次 forward、288 次 Q/K/V 比较通过，
      CPU/FPGA 生成文本一致。
- [x] 确认当前主要耗时：
      输入读回校验 52.74%，START-to-DONE 34.64%，W 复制 8.72%。

### 下一阶段：软件性能测量

- [ ] 保存当前 Q/K/V 计时验证基线及构建信息。
- [ ] 从实际工程确认 GEMV 时钟频率并写入性能记录。
- [ ] 增加显式的验证模式和性能模式：
      验证模式保留现有完整检查；
      性能模式关闭 CPU 参考计算、完整输入读回和逐调用日志。
- [ ] 性能模式继续保留 VERSION、尺寸/地址范围、BUSY、
      完成状态、错误和超时检查；失败后不自动重试。
- [ ] 在同一映像下对比 CPU、FPGA 验证模式、FPGA 性能模式。
- [ ] 固定模型、tokenizer、prompt、编译选项和线程设置，
      重复测量并保存文本、退出状态与分项统计。

### 后续：权重常驻共享 DDR

- [ ] 为全部层的 Q/K/V 权重建立明确的物理地址分配表。
- [ ] 初始化时复制权重并校验，推理期间不再重复复制 W。
- [ ] 每次调用仅更新 x、配置对应权重地址、读取 y。
- [ ] 更新接口，使软件能选择不同层、不同投影的常驻权重。
- [ ] 验证模式完成逐位回归后，再比较性能变化。

### 后续：提高 RTL 吞吐量

- [ ] 确认厂商 FP32 IP 的实际延迟和连续输入能力。
- [ ] 设计连续运算的数据通路，替代当前串行等待封装。
- [ ] 处理浮点累加反馈依赖，选择交错累加或多行交错方案。
- [ ] 根据累加顺序是否变化制定对应的数值验收标准。
- [ ] 增加权重读取 FIFO，使 DDR 读取与计算重叠。
- [ ] 逐步增加 AXI burst，再评估多个未完成事务和并行 lane。
- [ ] 完成功能、协议、时序和板上性能验证。

### 后续：扩大模型卸载范围

- [ ] 扩展软件库对矩形 GEMV 的支持。
- [ ] 按实际耗时逐步接入 Wo、FFN 和分类头。
- [ ] 扩展到更多 prompt、token 和较长序列验证。
- [ ] 在 FP32 路径稳定后评估 runq.c 对应的 int8 方案。