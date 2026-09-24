#!/usr/bin/env bash
set -euo pipefail

# 工具放在脚本所在目录
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
READ_TOOL="$SCRIPT_DIR/mmio_read"
WRITE_TOOL="$SCRIPT_DIR/mmio_write"

# CSR 地址
CTRL=0x20020000
STATUS=0x20020004
ADDR_LOW=0x20020008
ADDR_HIGH=0x2002000C
LENGTH=0x20020010
PATTERN=0x20020014
ERROR_COUNT=0x20020018
CYCLE_COUNT=0x2002001C

# 测试配置
TEST_ADDR=0xB8000000
TIMEOUT_SEC=5
VALUE=0

fail() {
    printf '\n[FAIL] %s\n' "$*" >&2
    exit 1
}

[[ $EUID -eq 0 ]] || fail "请使用 sudo bash \"$0\" 运行。"
[[ -x "$READ_TOOL" ]] || fail "找不到可执行工具：$READ_TOOL"
[[ -x "$WRITE_TOOL" ]] || fail "找不到可执行工具：$WRITE_TOOL"

# 如果系统提供 timeout，为每次工具调用设置独立超时。
TOOL_PREFIX=()
if command -v timeout >/dev/null 2>&1; then
    TOOL_PREFIX=(timeout -k 1s 3s)
fi

# 读取 32 位寄存器，结果保存在全局变量 VALUE。
# 支持纯 0x数值，或“地址 ... 0x数值”形式。
# 取输出中最后一个 0x 开头的十六进制数。
read32() {
    local addr="$1" output rest hex="" token

    if ! output=$("${TOOL_PREFIX[@]}" "$READ_TOOL" "$addr" 2>&1); then
        fail "读取 $addr 失败或超时：$output"
    fi

    rest="$output"
    while [[ "$rest" =~ 0[xX]([[:xdigit:]]+) ]]; do
        token="${BASH_REMATCH[0]}"
        hex="${BASH_REMATCH[1]}"
        rest="${rest#*"$token"}"
    done

    if [[ -z "$hex" ]]; then
        fail "无法解析 $addr 的读取结果，请贴回原始输出：$output"
    fi

    [[ "$hex" =~ ^0*[[:xdigit:]]{1,8}$ ]] ||
        fail "$addr 返回值超出 32 位范围：$output"

    VALUE=$((16#$hex))
}

write32() {
    local addr="$1" data="$2" output

    if ! output=$("${TOOL_PREFIX[@]}" "$WRITE_TOOL" "$addr" 32 "$data" 2>&1); then
        fail "写入 $addr = $data 失败或超时：$output"
    fi
}

# 写配置并立即读回验证。
set_checked() {
    local addr="$1" data="$2" expected
    expected=$((data))

    write32 "$addr" "$data"
    read32 "$addr"

    if (( VALUE != expected )); then
        printf '寄存器 %s：期望=0x%08X，实际=0x%08X\n' \
            "$addr" "$expected" "$VALUE" >&2
        fail "配置读回不一致。"
    fi
}

# 执行一轮测试并核对状态、错误计数。
run_test() {
    local name="$1" command="$2" expected_status="$3" expected_errors="$4"
    local deadline status errors cycles

    printf '\n[TEST] %s\n' "$name"

    read32 "$STATUS"
    (( (VALUE & 1) == 0 )) ||
        fail "启动前 IP 已处于 BUSY，停止后续操作。"

    write32 "$CTRL" "$command"
    deadline=$((SECONDS + TIMEOUT_SEC))

    while true; do
        read32 "$STATUS"
        status=$VALUE

        if (( (status & 1) == 0 )); then
            break
        fi

        if (( SECONDS >= deadline )); then
            read32 "$ERROR_COUNT"
            errors=$VALUE
            read32 "$CYCLE_COUNT"
            cycles=$VALUE

            printf 'STATUS=0x%08X  ERROR_COUNT=%u  CYCLE_COUNT=%u\n' \
                "$status" "$errors" "$cycles"

            fail "BUSY 超时。软件已停止；硬件事务可能仍未完成，CLEAR 不能取消事务。"
        fi

        sleep 0.1
    done

    read32 "$ERROR_COUNT"
    errors=$VALUE
    read32 "$CYCLE_COUNT"
    cycles=$VALUE

    printf 'STATUS=0x%08X  ERROR_COUNT=%u  CYCLE_COUNT=%u\n' \
        "$status" "$errors" "$cycles"

    if (( status != expected_status || errors != expected_errors )); then
        printf '期望：STATUS=0x%08X  ERROR_COUNT=%u\n' \
            "$expected_status" "$expected_errors"
        fail "$name：结果不符合预期，停止后续测试。"
    fi

    (( cycles > 0 )) || fail "$name：CYCLE_COUNT 为 0，需要检查。"

    printf '[PASS] %s\n' "$name"
}

printf 'DDR Test Master 自动测试\n'
printf '测试地址：%s，最大长度：256 字节\n' "$TEST_ADDR"

# 确认当前仍是 mem=896M 启动。
CMDLINE="$(cat /proc/cmdline)"
[[ " $CMDLINE " == *" mem=896M "* ]] ||
    fail "当前启动参数不含 mem=896M，请先按前面的方法带该参数启动。"

# 检查测试范围是否与当前 /proc/iomem 登记的区域重叠。
# 此检查不能发现未向 Linux 声明的固件或其他硬件用途。
while read -r range description; do
    if [[ "$range" =~ ^([[:xdigit:]]+)-([[:xdigit:]]+)$ ]]; then
        region_start=$((16#${BASH_REMATCH[1]}))
        region_end=$((16#${BASH_REMATCH[2]}))

        if (( region_start <= TEST_ADDR + 0xFF &&
              region_end >= TEST_ADDR )); then
            fail "测试范围与当前内存资源重叠：$range $description"
        fi
    fi
done < /proc/iomem

# 确认空闲，再清除旧结果。
read32 "$STATUS"
printf '初始 STATUS=0x%08X\n' "$VALUE"
(( (VALUE & 1) == 0 )) || fail "IP 当前 BUSY，停止测试。"

write32 "$CTRL" 0x4
read32 "$STATUS"
(( VALUE == 0 )) || fail "CLEAR 后 STATUS 未归零。"
read32 "$ERROR_COUNT"
(( VALUE == 0 )) || fail "CLEAR 后 ERROR_COUNT 未归零。"

# 第一组：16 字节，一个 128 位数据拍。
set_checked "$ADDR_LOW" "$TEST_ADDR"
set_checked "$ADDR_HIGH" 0x0
set_checked "$LENGTH" 0x10
set_checked "$PATTERN" 0x5A5A5A5A

run_test "16 字节写入，模式 0x5A5A5A5A" 0x1 0x02 0
run_test "16 字节读校验，模式 0x5A5A5A5A" 0x3 0x02 0

# 仅改变比较模式，不写 DDR；预期一个事务比较失败。
set_checked "$PATTERN" 0xA5A5A5A5
run_test "故意错模式读校验，预期 DATA_ERROR" 0x3 0x26 1

# 恢复比较模式，不重新写 DDR；预期恢复通过。
set_checked "$PATTERN" 0x5A5A5A5A
run_test "恢复正确模式后的读校验" 0x3 0x02 0

# 第二组：256 字节，16 个单拍事务。
set_checked "$LENGTH" 0x100
set_checked "$PATTERN" 0x12345678

run_test "256 字节写入，模式 0x12345678" 0x1 0x02 0
run_test "256 字节读校验，模式 0x12345678" 0x3 0x02 0

printf '\n[ALL PASS] 六轮 FPGA DDR 自测均符合预期。\n'
printf '最终测试范围：0xB8000000–0xB80000FF\n'
printf '最终写入模式：每个 32 位字为 0x12345678\n'