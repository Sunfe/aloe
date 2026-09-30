#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# 文件：board_test_common.sh
# 用途：当前三 IP 映像的地址配置、MMIO 访问和公共检查。
#
# 这是公共库，不是独立测试，不要直接运行。
# 由 test_ddr_master_selftest.sh / test_fp32_dsp_board.sh 加载。
#
# 当前 HPS 物理地址：
#   GEMV             0x20020000
#   DDR Test Master  0x20021000
#   FP32 Board Test  0x20022000
#
# 运行前只读检查 GEMV/FP32 VERSION，发现不匹配就停止。
# DDR Test Master 本身没有 VERSION 寄存器。
#
# 注意：
#   空闲检查不是互斥锁。所有测试仍必须串行运行。
#   工具超时或脚本退出不会撤销 FPGA 已发出的 AXI 事务。
# -----------------------------------------------------------------------------

BOARD_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

GEMV_BASE=0x20020000
DDR_BASE=0x20021000
FP32_BASE=0x20022000

GEMV_VERSION=0x474D5631
FP32_VERSION=0x46500001

SHARED_BEGIN=0xB8000000
SHARED_END=0xC0000000

READ_TOOL="$BOARD_DIR/mmio_read"
WRITE_TOOL="$BOARD_DIR/mmio_write"

VALUE=0
STATUS_WORD=0
TOOL_PREFIX=()

fail() {
    printf '\n[FAIL] %s\n' "$*" >&2
    exit 1
}

# 与已经通过的交换测试采用相同的 mmio_read 输出解析规则：
# 取输出中最后一个 0x 开头的十六进制数。
read32() {
    local addr="$1"
    local output rest token hex=""

    if ! output=$(
        "${TOOL_PREFIX[@]}" "$READ_TOOL" "$addr" 2>&1
    ); then
        fail "读取 $addr 失败或超时：$output"
    fi

    rest="$output"
    while [[ "$rest" =~ 0[xX]([[:xdigit:]]+) ]]; do
        token="${BASH_REMATCH[0]}"
        hex="${BASH_REMATCH[1]}"
        rest="${rest#*"$token"}"
    done

    [[ -n "$hex" ]] ||
        fail "无法解析 $addr 的读取结果：$output"

    while [[ ${#hex} -gt 1 && "${hex:0:1}" == "0" ]]; do
        hex="${hex:1}"
    done

    [[ ${#hex} -le 8 ]] ||
        fail "$addr 返回值超出 32 位范围：$output"

    VALUE=$((16#$hex))
}

write32() {
    local addr="$1"
    local data="$2"
    local output

    if ! output=$(
        "${TOOL_PREFIX[@]}" "$WRITE_TOOL" "$addr" 32 "$data" 2>&1
    ); then
        fail "写入 $addr=$data 失败或超时：$output；硬件操作可能已发生，不自动重试。"
    fi
}

# 用法：read_reg <base> <offset>
# 读取结果仍存放在 VALUE 中。
read_reg() {
    local addr
    printf -v addr '0x%08X' "$(($1 + $2))"
    read32 "$addr"
}

# 用法：write_reg <base> <offset> <value>
write_reg() {
    local addr
    printf -v addr '0x%08X' "$(($1 + $2))"
    write32 "$addr" "$3"
}

expect_reg() {
    local base="$1"
    local offset="$2"
    local expected="$3"
    local label="$4"

    read_reg "$base" "$offset"

    if (( VALUE != expected )); then
        printf '%s：地址=0x%08X，期望=0x%08X，实际=0x%08X\n' \
            "$label" "$((base + offset))" \
            "$((expected))" "$VALUE" >&2
        fail "$label 不符合预期，停止后续操作。"
    fi
}

set_reg_checked() {
    local base="$1"
    local offset="$2"
    local data="$3"

    write_reg "$base" "$offset" "$data"
    expect_reg "$base" "$offset" "$data" "配置读回"
}

require_idle() {
    local base="$1"
    local name="$2"

    read_reg "$base" 0x04

    if (( (VALUE & 1) != 0 )); then
        printf '%s STATUS=0x%08X\n' "$name" "$VALUE" >&2
        fail "$name 正在 BUSY；不清除状态、不启动新的测试。"
    fi
}

# 等待 BUSY=0 且 DONE=1。
# 不要求软件必须观察到 BUSY=1，短操作可能在第一次读取前已经完成。
wait_done() {
    local base="$1"
    local timeout_sec="$2"
    local deadline=$((SECONDS + timeout_sec))

    while true; do
        read_reg "$base" 0x04
        STATUS_WORD=$VALUE

        if (( (STATUS_WORD & 1) == 0 &&
              (STATUS_WORD & 2) != 0 )); then
            return 0
        fi

        if (( SECONDS >= deadline )); then
            printf 'CSR=0x%08X STATUS=0x%08X\n' \
                "$((base))" "$STATUS_WORD" >&2
            fail "等待 DONE 超时；不会发送 CLEAR 或重试 START。"
        fi

        sleep 0.05
    done
}

require_shared_memory() {
    local cmdline

    [[ -r /proc/cmdline ]] ||
        fail "无法读取 /proc/cmdline。"

    cmdline="$(</proc/cmdline)"

    [[ " $cmdline " == *" mem=896M "* ]] ||
        fail "启动参数不含 mem=896M，停止共享 DDR 测试。"
}

check_ddr_range() {
    local addr="$1"
    local bytes="$2"

    (( bytes > 0 )) ||
        fail "DDR 测试长度必须大于零。"

    (( (addr & 15) == 0 && (bytes & 15) == 0 )) ||
        fail "FPGA DDR 测试地址和长度必须为 16 字节对齐。"

    (( addr >= SHARED_BEGIN && addr < SHARED_END )) ||
        fail "地址超出共享 DDR 范围。"

    (( bytes <= SHARED_END - addr )) ||
        fail "测试范围超出共享 DDR 结束地址。"
}

board_init() {
    [[ $EUID -eq 0 ]] ||
        fail "请使用 sudo bash 运行测试脚本。"

    [[ -x "$READ_TOOL" ]] ||
        fail "找不到可执行工具：$READ_TOOL"

    [[ -x "$WRITE_TOOL" ]] ||
        fail "找不到可执行工具：$WRITE_TOOL"

    if command -v timeout >/dev/null 2>&1; then
        TOOL_PREFIX=(timeout -k 1s 5s)
    else
        printf '[WARN] 未找到 timeout，工具调用没有独立超时保护。\n'
    fi

    trap 'printf "\n[STOP] 用户中断；硬件操作可能仍在执行。\n" >&2; exit 130' INT
    trap 'printf "\n[STOP] 脚本终止；硬件操作可能仍在执行。\n" >&2; exit 143' TERM

    printf '[MAP] GEMV=0x%08X DDR=0x%08X FP32=0x%08X\n' \
        "$((GEMV_BASE))" "$((DDR_BASE))" "$((FP32_BASE))"

    # 先读取身份寄存器，版本不匹配时不进行任何测试写入。
    expect_reg "$GEMV_BASE" 0x24 "$GEMV_VERSION" "GEMV VERSION"
    expect_reg "$FP32_BASE" 0x18 "$FP32_VERSION" "FP32 VERSION"

    printf '[ID] GEMV VERSION=0x%08X，FP32 VERSION=0x%08X\n' \
        "$((GEMV_VERSION))" "$((FP32_VERSION))"

    require_idle "$GEMV_BASE" "GEMV"
    require_idle "$DDR_BASE" "DDR Test Master"
    require_idle "$FP32_BASE" "FP32 Board Test"
}