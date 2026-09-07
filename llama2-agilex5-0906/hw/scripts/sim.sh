#!/usr/bin/env bash
# 用法: ./sim.sh tb_pe_array | tb_w_reader | tb_matvec_top   [N D]
set -euo pipefail
TB=${1:-tb_pe_array}; N=${2:-768}; D=${3:-768}
cd "$(dirname "$0")/../tb"
python3 golden/gen_vectors.py "$N" "$D" && mkdir -p golden && mv -f w.hex x.hex y_ref.hex golden/
rm -rf work && vlib work
# 不定义 SYNTHESIS -> fp32 走行为模型. 验证 IP 时改用 vsim -L 加 Quartus 仿真库并 +define+SYNTHESIS
vlog -sv ../rtl/pkg/matvec_pkg.sv ../rtl/fp32_prims.sv ../rtl/csr.sv ../rtl/x_buf.sv ../rtl/y_buf.sv \
        ../rtl/w_reader.sv ../rtl/pe_array.sv ../rtl/matvec_top.sv axi_mem_model.sv "$TB.sv"
vsim -c "$TB" -do "run -all; quit"