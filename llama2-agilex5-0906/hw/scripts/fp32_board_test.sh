#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
READ_TOOL="$SCRIPT_DIR/mmio_read"
WRITE_TOOL="$SCRIPT_DIR/mmio_write"

fail() {
    printf '\n[FAIL] %s\n' "$*" >&2
    exit 1
}

[[ $EUID -eq 0 ]] || fail "请使用 sudo bash \"$0\" 运行。"
[[ -x "$READ_TOOL" ]] || fail "找不到 $READ_TOOL"
[[ -x "$WRITE_TOOL" ]] || fail "找不到 $WRITE_TOOL"

# Address Map:
# lwhps2fpga offset 0x00021000
# physical CSR base 0x20021000
BASE_TEXT="${1:-0x20021000}"

[[ "$BASE_TEXT" =~ ^0[xX][[:xdigit:]]{1,8}$ ]] ||
    fail "基地址必须是最多 8 位的十六进制地址。"

BASE=$((BASE_TEXT))
(( (BASE & 0x3F) == 0 )) || fail "基地址必须按 64 字节对齐。"
(( BASE <= 0xFFFFFFC0 )) || fail "寄存器范围越界。"

printf -v CTRL     '0x%08X' "$((BASE + 0x00))"
printf -v STATUS   '0x%08X' "$((BASE + 0x04))"
printf -v A_REG    '0x%08X' "$((BASE + 0x08))"
printf -v B_REG    '0x%08X' "$((BASE + 0x0C))"
printf -v RESULT   '0x%08X' "$((BASE + 0x10))"
printf -v CYCLES   '0x%08X' "$((BASE + 0x14))"
printf -v VERSION  '0x%08X' "$((BASE + 0x18))"
printf -v COMPLETE '0x%08X' "$((BASE + 0x1C))"
printf -v DEBUG    '0x%08X' "$((BASE + 0x20))"

TIMEOUT_SEC=5
VALUE=0
PASS_COUNT=0

TOOL_PREFIX=()
if command -v timeout >/dev/null 2>&1; then
    TOOL_PREFIX=(timeout -k 1s 3s)
fi

read32() {
    local addr="$1" output rest token hex=""

    if ! output=$("${TOOL_PREFIX[@]}" "$READ_TOOL" "$addr" 2>&1); then
        fail "读取 $addr 失败或超时：$output"
    fi

    rest="$output"

    while [[ "$rest" =~ 0[xX]([[:xdigit:]]+) ]]; do
        token="${BASH_REMATCH[0]}"
        hex="${BASH_REMATCH[1]}"
        rest="${rest#*"$token"}"
    done

    [[ -n "$hex" ]] || fail "无法解析读取结果：$output"

    # Accept zero-padded output, but reject values wider than 32 bits.
    while (( ${#hex} > 1 )) && [[ "${hex:0:1}" == "0" ]]; do
        hex="${hex:1}"
    done

    (( ${#hex} <= 8 )) || fail "返回值超过 32 位：$output"
    VALUE=$((16#$hex))
}

write32() {
    local addr="$1" data="$2" output

    if ! output=$(
        "${TOOL_PREFIX[@]}" "$WRITE_TOOL" "$addr" 32 "$data" 2>&1
    ); then
        fail "写入 $addr = $data 失败或超时：$output"
    fi
}

set_checked() {
    local addr="$1" data="$2"
    write32 "$addr" "$data"
    read32 "$addr"

    if (( VALUE != data )); then
        printf '配置读回错误：地址=%s 期望=0x%08X 实际=0x%08X\n' \
            "$addr" "$((data))" "$VALUE" >&2
        fail "操作数寄存器读回不一致。"
    fi
}

run_case() {
    local name="$1" command="$2" aval="$3" bval="$4" expected="$5"
    local old_count new_count deadline status actual cycles debug

    read32 "$STATUS"
    (( (VALUE & 1) == 0 )) ||
        fail "启动前已 BUSY；停止测试，不自动清除或重试。"

    write32 "$CTRL" 0x4

    read32 "$STATUS"
    (( VALUE == 0 )) || fail "CLEAR 后 STATUS 不为 0。"

    set_checked "$A_REG" "$aval"
    set_checked "$B_REG" "$bval"

    read32 "$COMPLETE"
    old_count=$VALUE

    write32 "$CTRL" "$command"
    deadline=$((SECONDS + TIMEOUT_SEC))

    while true; do
        read32 "$STATUS"
        status=$VALUE

        if (( status == 2 )); then
            break
        fi

        if (( SECONDS >= deadline )); then
            read32 "$DEBUG"
            debug=$VALUE

            printf '超时：STATUS=0x%08X DEBUG=0x%08X\n' \
                "$status" "$debug" >&2

            fail "$name 超时。停止测试；CLEAR 不能取消正在进行的操作。"
        fi

        sleep 0.01
    done

    read32 "$RESULT"
    actual=$VALUE

    read32 "$CYCLES"
    cycles=$VALUE

    read32 "$COMPLETE"
    new_count=$VALUE

    if (( new_count != ((old_count + 1) & 0xFFFFFFFF) )); then
        fail "$name：完成计数没有恰好增加 1。"
    fi

    (( cycles > 0 )) || fail "$name：周期计数为 0。"

    if (( actual != expected )); then
        printf \
            '[MISMATCH] %s A=%s B=%s expected=0x%08X actual=0x%08X cycles=%u\n' \
            "$name" "$aval" "$bval" "$((expected))" "$actual" "$cycles" >&2
        fail "浮点结果不匹配。"
    fi

    PASS_COUNT=$((PASS_COUNT + 1))

    printf '[PASS] %-18s result=0x%08X cycles=%u completed=%u\n' \
        "$name" "$actual" "$cycles" "$new_count"
}

printf 'FP32 板上测试，CSR 基地址：0x%08X\n' "$BASE"

read32 "$VERSION"
printf 'VERSION=0x%08X\n' "$VALUE"

(( VALUE == 0x46500001 )) ||
    fail "VERSION 不匹配，请检查地址映射和 FPGA 配置文件。"

# name               command A          B          expected
CASES=(
    "MUL_2x3             0x1 0x40000000 0x40400000 0x40C00000"
    "ADD_6plus4          0x3 0x40C00000 0x40800000 0x41200000"
    "MUL_neg1p5x2        0x1 0xBFC00000 0x40000000 0xC0400000"
    "ADD_neg3plus1       0x3 0xC0400000 0x3F800000 0xC0000000"
    "MUL_half_x_quarter  0x1 0x3F000000 0x3E800000 0x3E000000"
    "ADD_eighth_plus_half 0x3 0x3E000000 0x3F000000 0x3F200000"
    "MUL_zero_x5         0x1 0x00000000 0x40A00000 0x00000000"
    "ADD_1plus_neg1      0x3 0x3F800000 0xBF800000 0x00000000"
)

for round in 1 2 3; do
    printf '\n===== 第 %u 轮 =====\n' "$round"

    for entry in "${CASES[@]}"; do
        read -r name command aval bval expected <<< "$entry"
        run_case "$name" "$command" "$aval" "$bval" "$expected"
    done
done

printf '\n[ALL PASS] %u 次 FP32 板上运算全部通过。\n' "$PASS_COUNT"