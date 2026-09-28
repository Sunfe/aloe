#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# 文件：test_ddr_hps_fpga_exchange.sh
#
# 功能：
#   验证 HPS 与 FPGA 通过共享 DDR 进行双向数据交换。
#
# 测试方向：
#   1. HPS 写入指定模式，FPGA DDR Test Master 读取并校验。
#   2. FPGA DDR Test Master 写入指定模式，HPS 读取并校验。
#
# 与 FPGA 自测的区别：
#   test_ddr_master_selftest.sh：
#       FPGA 写、FPGA 读；HPS 主要负责控制 CSR。
#   本脚本：
#       HPS 写、FPGA 读，以及 FPGA 写、HPS 读。
#
# 当前映像地址：
#   DDR Test Master CSR = 0x20021000
#   注意：0x20020000 是当前 GEMV CSR，不要混用。
#
# 测试区域：
#   0xB8000000，4 KiB
#   0xBA000000，64 KiB
#   0xBFF00000，1 MiB
#
# 依赖：
#   同目录中的 mmio_read、mmio_write、shared_ddr_rw_tool。
#   若尚未重命名，兼容同目录中的旧程序 shared_mem_tool。
#   不依赖 shared_ddr_rw.sh；本脚本自行检查共享区范围。
#
# 前提：
#   必须以 root 运行，Linux 启动参数必须包含 mem=896M。
#   当前 FPGA 映像和实际地址映射必须与上述配置一致。
#
# 警告：
#   本测试会覆盖上述三个区域，包括 GEMV 的 W 数据区域。
#   不得与 GEMV、其他 DDR 测试或其他共享内存使用者并发运行。
#   检查 DDR Test Master 空闲不能证明其他硬件模块也处于空闲。
#   软件超时或退出不会取消已经发出的 FPGA AXI 事务。
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

READ_TOOL="$SCRIPT_DIR/mmio_read"
WRITE_TOOL="$SCRIPT_DIR/mmio_write"
MEM_TOOL="$SCRIPT_DIR/shared_ddr_rw_tool"

# 兼容尚未重命名的旧工具。
if [[ ! -x "$MEM_TOOL" && -x "$SCRIPT_DIR/shared_mem_tool" ]]; then
    MEM_TOOL="$SCRIPT_DIR/shared_mem_tool"
fi

# 当前已确认的 DDR Test Master CSR 基地址。
DDR_CSR_BASE=0x20021000

printf -v CTRL        '0x%08X' "$((DDR_CSR_BASE + 0x00))"
printf -v STATUS      '0x%08X' "$((DDR_CSR_BASE + 0x04))"
printf -v ADDR_LOW    '0x%08X' "$((DDR_CSR_BASE + 0x08))"
printf -v ADDR_HIGH   '0x%08X' "$((DDR_CSR_BASE + 0x0C))"
printf -v LENGTH      '0x%08X' "$((DDR_CSR_BASE + 0x10))"
printf -v PATTERN     '0x%08X' "$((DDR_CSR_BASE + 0x14))"
printf -v ERROR_COUNT '0x%08X' "$((DDR_CSR_BASE + 0x18))"
printf -v CYCLE_COUNT '0x%08X' "$((DDR_CSR_BASE + 0x1C))"

SHARED_BEGIN=0xB8000000
SHARED_END=0xC0000000       # 结束地址不包含
TIMEOUT_SEC=10

VALUE=0
PASSED=0

# 每行：DDR 地址、字节数、HPS->FPGA 模式、FPGA->HPS 模式。
TEST_CASES=(
    "0xB8000000 0x00001000 0xA5A5A5A5 0x5A5A5A5A"
    "0xBA000000 0x00010000 0x12345678 0x87654321"
    "0xBFF00000 0x00100000 0x55AA55AA 0xAA55AA55"
)

fail() {
    printf '\n[FAIL] %s\n' "$*" >&2
    exit 1
}

[[ $# -eq 0 ]] ||
    fail "本脚本不接收参数；地址和测试区域在文件头部配置。"

[[ $EUID -eq 0 ]] ||
    fail "请使用 sudo bash \"$0\" 运行。"

[[ -x "$READ_TOOL" ]] ||
    fail "找不到可执行工具：$READ_TOOL"

[[ -x "$WRITE_TOOL" ]] ||
    fail "找不到可执行工具：$WRITE_TOOL"

[[ -x "$MEM_TOOL" ]] ||
    fail "找不到 shared_ddr_rw_tool 或 shared_mem_tool，请先编译 C 工具。"

[[ -r /proc/cmdline ]] ||
    fail "无法读取 /proc/cmdline。"

CMDLINE="$(</proc/cmdline)"
[[ " $CMDLINE " == *" mem=896M "* ]] ||
    fail "启动参数不含 mem=896M，停止测试。"

# 单次工具调用超时。
# 没有 timeout 时仍可执行，但不能限制卡住的工具进程。
TOOL_PREFIX=()
if command -v timeout >/dev/null 2>&1; then
    TOOL_PREFIX=(timeout -k 1s 5s)
else
    printf '[WARN] 未找到 timeout，单次工具调用没有独立超时保护。\n'
fi

# 中断时不发送 CLEAR，也不尝试重启硬件。
trap 'printf "\n[STOP] 用户中断；FPGA 事务可能仍在执行，请先确认硬件状态。\n" >&2; exit 130' INT
trap 'printf "\n[STOP] 脚本终止；FPGA 事务可能仍在执行，请先确认硬件状态。\n" >&2; exit 143' TERM

# 读取 32 位寄存器。
# 与现有脚本一致：取 mmio_read 输出中最后一个 0x 十六进制数。
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

    # 去除多余前导零，再检查是否为 32 位数值。
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
        fail "写入 $addr=$data 失败或超时：$output。若已提交 START，硬件可能仍在执行。"
    fi
}

# 写配置并读回，避免在配置不一致时启动 FPGA。
set_checked() {
    local addr="$1"
    local data="$2"
    local expected=$((data))

    write32 "$addr" "$data"
    read32 "$addr"

    if (( VALUE != expected )); then
        printf '地址=%s 期望=0x%08X 实际=0x%08X\n' \
            "$addr" "$expected" "$VALUE" >&2
        fail "寄存器配置读回不一致。"
    fi
}

check_range() {
    local addr=$(( $1 ))
    local bytes=$(( $2 ))

    (( bytes > 0 )) ||
        fail "测试长度必须大于零。"

    (( (addr & 0xF) == 0 && (bytes & 0xF) == 0 )) ||
        fail "FPGA DDR 测试地址和长度必须为 16 字节对齐。"

    (( addr >= SHARED_BEGIN && addr < SHARED_END )) ||
        fail "起始地址超出共享 DDR 范围。"

    (( bytes <= SHARED_END - addr )) ||
        fail "测试范围越过共享 DDR 结束地址 0xC0000000。"
}

assert_fpga_idle() {
    read32 "$STATUS"

    if (( (VALUE & 1) != 0 )); then
        printf 'STATUS=0x%08X\n' "$VALUE" >&2
        fail "DDR Test Master 正在 BUSY；不覆盖测试数据、不发送 CLEAR。"
    fi
}

# 调用现有 C 工具执行 HPS 侧访问。
run_hps_mem() {
    local operation="$1"
    local addr="$2"
    local bytes="$3"
    local pattern="$4"

    check_range "$addr" "$bytes"
    assert_fpga_idle

    if ! "${TOOL_PREFIX[@]}" "$MEM_TOOL" \
            "$operation" "$addr" "$bytes" "$pattern"; then
        fail "HPS $operation 失败或超时，停止后续测试。"
    fi
}

# 执行一次 FPGA DDR 操作。
# command=0x1：FPGA 写入模式。
# command=0x3：FPGA 读取并校验模式。
run_fpga() {
    local command="$1"
    local addr="$2"
    local bytes="$3"
    local pattern="$4"
    local deadline status errors cycles

    check_range "$addr" "$bytes"
    assert_fpga_idle

    # 只在空闲时清除旧结果，避免误把上一次 DONE 当成新结果。
    write32 "$CTRL" 0x4

    read32 "$STATUS"
    (( VALUE == 0 )) ||
        fail "CLEAR 后 STATUS 未归零。"

    read32 "$ERROR_COUNT"
    (( VALUE == 0 )) ||
        fail "CLEAR 后 ERROR_COUNT 未归零。"

    read32 "$CYCLE_COUNT"
    (( VALUE == 0 )) ||
        fail "CLEAR 后 CYCLE_COUNT 未归零。"

    set_checked "$ADDR_LOW" "$addr"
    set_checked "$ADDR_HIGH" 0x0
    set_checked "$LENGTH" "$bytes"
    set_checked "$PATTERN" "$pattern"

    write32 "$CTRL" "$command"
    deadline=$((SECONDS + TIMEOUT_SEC))

    while true; do
        read32 "$STATUS"
        status=$VALUE

        # 必须同时满足 BUSY=0、DONE=1。
        if (( (status & 1) == 0 && (status & 2) != 0 )); then
            break
        fi

        if (( SECONDS >= deadline )); then
            printf '超时 STATUS=0x%08X\n' "$status" >&2

            read32 "$ERROR_COUNT"
            printf 'ERROR_COUNT=%u\n' "$VALUE" >&2

            read32 "$CYCLE_COUNT"
            printf 'CYCLE_COUNT=%u\n' "$VALUE" >&2

            fail "等待 FPGA DONE 超时。不会发送 CLEAR 或重试 START；请先检查硬件。"
        fi

        sleep 0.05
    done

    read32 "$ERROR_COUNT"
    errors=$VALUE

    read32 "$CYCLE_COUNT"
    cycles=$VALUE

    printf 'FPGA：STATUS=0x%08X ERROR_COUNT=%u CYCLE_COUNT=%u\n' \
        "$status" "$errors" "$cycles"

    (( status == 0x02 && errors == 0 )) ||
        fail "FPGA 操作失败，预期 STATUS=0x02、ERROR_COUNT=0。"

    (( cycles > 0 )) ||
        fail "FPGA CYCLE_COUNT 为零，请检查 CSR 地址及硬件。"
}

# 在第一次写入前，检查全部测试区域。
for entry in "${TEST_CASES[@]}"; do
    read -r addr bytes hps_pattern fpga_pattern <<< "$entry"
    check_range "$addr" "$bytes"

    (( hps_pattern != fpga_pattern )) ||
        fail "两个方向的测试模式必须不同。"
done

printf 'HPS-FPGA 共享 DDR 双向交换测试\n'
printf 'DDR Test Master CSR：0x%08X\n' "$DDR_CSR_BASE"
printf 'HPS 内存工具：%s\n' "$MEM_TOOL"
printf '注意：将覆盖三个测试区域，请勿同时运行 GEMV 或其他 DDR 测试。\n'

assert_fpga_idle

for entry in "${TEST_CASES[@]}"; do
    read -r addr bytes hps_pattern fpga_pattern <<< "$entry"

    printf '\n==================================================\n'
    printf '测试范围：0x%08X–0x%08X，共 %u 字节\n' \
        "$((addr))" "$((addr + bytes - 1))" "$((bytes))"

    # ---------------------------------------------------------
    # 方向一：HPS 写，FPGA 读并校验。
    # ---------------------------------------------------------
    printf '\n[TEST] HPS -> FPGA，模式=0x%08X\n' "$((hps_pattern))"

    run_hps_mem fill  "$addr" "$bytes" "$hps_pattern"
    run_hps_mem check "$addr" "$bytes" "$hps_pattern"

    run_fpga 0x3 "$addr" "$bytes" "$hps_pattern"

    PASSED=$((PASSED + 1))
    printf '[PASS] HPS 写入，FPGA 读取并校验\n'

    # ---------------------------------------------------------
    # 方向二：FPGA 写，HPS 读并校验。
    #
    # 先写入目标模式的按位取反值，并由 HPS 读回确认。
    # 避免 DDR 原本就等于目标值，导致“没有真正写入也通过”。
    # ---------------------------------------------------------
    printf -v poison '0x%08X' \
        "$((fpga_pattern ^ 0xFFFFFFFF))"

    printf '\n[TEST] FPGA -> HPS，模式=0x%08X\n' "$((fpga_pattern))"

    run_hps_mem fill  "$addr" "$bytes" "$poison"
    run_hps_mem check "$addr" "$bytes" "$poison"

    run_fpga 0x1 "$addr" "$bytes" "$fpga_pattern"

    run_hps_mem check "$addr" "$bytes" "$fpga_pattern"

    PASSED=$((PASSED + 1))
    printf '[PASS] FPGA 写入，HPS 读取并校验\n'
done

printf '\n[ALL PASS] %u 个位置 × 2 个方向，共 %u 项交换测试通过。\n' \
    "${#TEST_CASES[@]}" "$PASSED"

printf '注意：测试区域内容已改变；再次测试 GEMV 时需重新写入 W/x。\n'