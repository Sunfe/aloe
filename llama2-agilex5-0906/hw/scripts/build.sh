#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../quartus"
qsys-generate ../qsys/de25_llama.qsys --synthesis=VERILOG --quartus-project=de25_llama.qpf
quartus_sh --flow compile de25_llama
grep -A3 "Fmax" output_files/de25_llama.sta.rpt | head -20 || true