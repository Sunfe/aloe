#!/usr/bin/env bash
# Agilex 5: sof -> hps.rbf (HPS+IO, 进 QSPI/SD 引导链) + core.rbf (Linux 下由 FPGA manager 加载)
set -euo pipefail
cd "$(dirname "$0")/../quartus/output_files"
quartus_pfg -c -o hps=1 de25_llama.sof de25_llama.rbf
ls -l de25_llama.hps.rbf de25_llama.core.rbf
# 把 core.rbf 拷到板子 /lib/firmware/, 由设备树 overlay 的 firmware-name 引用.
# hps.rbf 是否需要重新烧: 只要 HPS 配置 (引脚/DDR/时钟) 与 GHRD 一致就不用; 具体引导链以 Terasic 手册为准.