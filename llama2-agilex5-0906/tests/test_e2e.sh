#!/bin/sh
# 贪心采样下 CPU 与 FPGA 输出必须逐字相同
set -e
cd "$(dirname "$0")/../sw"
MODEL=${1:-stories15M.bin}
PROMPT="Once upon a time"
./run_accel "$MODEL" -t 0 -n 128 -i "$PROMPT" -a 0 > /tmp/cpu.txt  2> /tmp/cpu.err
./run_accel "$MODEL" -t 0 -n 128 -i "$PROMPT" -a 1 > /tmp/fpga.txt 2> /tmp/fpga.err
grep "tok/s" /tmp/cpu.err /tmp/fpga.err || true
if diff /tmp/cpu.txt /tmp/fpga.txt; then echo "E2E PASS"; else echo "E2E FAIL"; exit 1; fi