#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# 文件：test_fp32_dsp_board.sh
# 功能：独立测试 fp32_board_test_0 的 FP32 乘法和加法。
#
# 地址配置来自 board_test_common.sh。
# 当前 FP32 CSR = 0x20022000，VERSION = 0x46500001。
#
# 共 24 项基础功能测试：
#   12 次乘法、12 次加法。
#   这里只测试列出的有限值，不是完整 IEEE-754 边界行为测试。
#
# 本脚本不读写共享 DDR。
# COMPLETED 使用运行前读数作基准，不要求它从零开始。
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/board_test_common.sh"

PASSED=0

run_case() {
    local name="$1"
    local command="$2"
    local a="$3"
    local b="$4"
    local expected="$5"
    local status result cycles before after next

    printf '\n[TEST] %s\n' "$name"

    require_idle "$FP32_BASE" "FP32 Board Test"

    read_reg "$FP32_BASE" 0x1C
    before=$VALUE

    write_reg "$FP32_BASE" 0x00 0x4

    expect_reg "$FP32_BASE" 0x04 0 "CLEAR 后 STATUS"
    expect_reg "$FP32_BASE" 0x10 0 "CLEAR 后 RESULT"
    expect_reg "$FP32_BASE" 0x14 0 "CLEAR 后 CYCLES"

    set_reg_checked "$FP32_BASE" 0x08 "$a"
    set_reg_checked "$FP32_BASE" 0x0C "$b"

    write_reg "$FP32_BASE" 0x00 "$command"
    wait_done "$FP32_BASE" 5
    status=$STATUS_WORD

    read_reg "$FP32_BASE" 0x10
    result=$VALUE

    read_reg "$FP32_BASE" 0x14
    cycles=$VALUE

    read_reg "$FP32_BASE" 0x1C
    after=$VALUE
    next=$(((before + 1) & 0xFFFFFFFF))

    printf 'A=0x%08X B=0x%08X RESULT=0x%08X EXPECTED=0x%08X\n' \
        "$((a))" "$((b))" "$result" "$((expected))"

    printf 'STATUS=0x%08X CYCLES=%u COMPLETED=%u\n' \
        "$status" "$cycles" "$after"

    (( status == 0x02 )) ||
        fail "$name 的 STATUS 不等于 0x02。"

    (( result == expected )) ||
        fail "$name 的 FP32 结果位模式不匹配。"

    (( cycles > 0 )) ||
        fail "$name 的 CYCLES 为零。"

    (( after == next )) ||
        fail "$name 的 COMPLETED 未增加 1。"

    PASSED=$((PASSED + 1))
    printf '[PASS] %s\n' "$name"
}

# 每行：
# 名称 CTRL A_bits B_bits EXPECTED_bits
#
# CTRL=0x1：乘法
# CTRL=0x3：加法
CASES=(
    "mul_2x3              0x1 0x40000000 0x40400000 0x40C00000"
    "mul_1x1              0x1 0x3F800000 0x3F800000 0x3F800000"
    "mul_neg2x3           0x1 0xC0000000 0x40400000 0xC0C00000"
    "mul_neg2xneg3        0x1 0xC0000000 0xC0400000 0x40C00000"
    "mul_halfxhalf        0x1 0x3F000000 0x3F000000 0x3E800000"
    "mul_1p5x2            0x1 0x3FC00000 0x40000000 0x40400000"
    "mul_0x7              0x1 0x00000000 0x40E00000 0x00000000"
    "mul_7x0              0x1 0x40E00000 0x00000000 0x00000000"
    "mul_4xquarter        0x1 0x40800000 0x3E800000 0x3F800000"
    "mul_neghalfx4        0x1 0xBF000000 0x40800000 0xC0000000"
    "mul_8x2              0x1 0x41000000 0x40000000 0x41800000"
    "mul_repeat_2x3       0x1 0x40000000 0x40400000 0x40C00000"

    "add_6plus4           0x3 0x40C00000 0x40800000 0x41200000"
    "add_1plus2           0x3 0x3F800000 0x40000000 0x40400000"
    "add_neg2plus3        0x3 0xC0000000 0x40400000 0x3F800000"
    "add_neg2plusneg3     0x3 0xC0000000 0xC0400000 0xC0A00000"
    "add_halfplusquarter  0x3 0x3F000000 0x3E800000 0x3F400000"
    "add_1p5plus2p5       0x3 0x3FC00000 0x40200000 0x40800000"
    "add_0plus7           0x3 0x00000000 0x40E00000 0x40E00000"
    "add_2plusneg2        0x3 0x40000000 0xC0000000 0x00000000"
    "add_neghalfplusquarter 0x3 0xBF000000 0x3E800000 0xBE800000"
    "add_2p5plus2p5       0x3 0x40200000 0x40200000 0x40A00000"
    "add_8plus8           0x3 0x41000000 0x41000000 0x41800000"
    "add_repeat_6plus4    0x3 0x40C00000 0x40800000 0x41200000"
)

printf 'FP32 DSP 板上测试：修正版 v2\n'
board_init

printf 'FP32 CSR=0x%08X，共 %u 项测试。\n' \
    "$((FP32_BASE))" "${#CASES[@]}"

for entry in "${CASES[@]}"; do
    read -r name command a b expected <<< "$entry"
    run_case "$name" "$command" "$a" "$b" "$expected"
done

printf '\n[ALL PASS] %u 项 FP32 板上运算通过。\n' "$PASSED"