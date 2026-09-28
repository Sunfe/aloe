#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# 文件：test_ddr_master_selftest.sh
# 功能：FPGA DDR Test Master 自测，不是 HPS-FPGA 双向交换测试。
#
# 测试项目：
#   16 字节写入、读校验、故意错模式、恢复正确模式；
#   256 字节写入、读校验。
#
# 地址配置统一来自 board_test_common.sh。
# 当前 DDR Test Master CSR = 0x20021000。
#
# 警告：
#   覆盖 0xB8000000–0xB80000FF，包括 GEMV 的 W 数据。
#   不得与其他共享 DDR 使用者并发运行。
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/board_test_common.sh"

TEST_ADDR=0xB8000000
PASSED=0

ddr_clear() {
    require_idle "$DDR_BASE" "DDR Test Master"

    write_reg "$DDR_BASE" 0x00 0x4

    expect_reg "$DDR_BASE" 0x04 0 "CLEAR 后 STATUS"
    expect_reg "$DDR_BASE" 0x18 0 "CLEAR 后 ERROR_COUNT"
    expect_reg "$DDR_BASE" 0x1C 0 "CLEAR 后 CYCLE_COUNT"
}

run_test() {
    local name="$1"
    local command="$2"
    local expected_status="$3"
    local expected_errors="$4"
    local status errors cycles

    printf '\n[TEST] %s\n' "$name"

    # 每次启动前清除旧 DONE，防止把旧结果当成新结果。
    # CLEAR 不修改 ADDR/LENGTH/PATTERN。
    ddr_clear

    write_reg "$DDR_BASE" 0x00 "$command"
    wait_done "$DDR_BASE" 10
    status=$STATUS_WORD

    read_reg "$DDR_BASE" 0x18
    errors=$VALUE

    read_reg "$DDR_BASE" 0x1C
    cycles=$VALUE

    printf 'STATUS=0x%08X ERROR_COUNT=%u CYCLE_COUNT=%u\n' \
        "$status" "$errors" "$cycles"

    if (( status != expected_status ||
          errors != expected_errors )); then
        printf '期望：STATUS=0x%08X ERROR_COUNT=%u\n' \
            "$((expected_status))" "$((expected_errors))" >&2
        fail "$name 结果不符合预期。"
    fi

    (( cycles > 0 )) ||
        fail "$name 的 CYCLE_COUNT 为零。"

    PASSED=$((PASSED + 1))
    printf '[PASS] %s\n' "$name"
}

printf 'DDR Test Master 自测：修正版 v2\n'

board_init
require_shared_memory
check_ddr_range "$TEST_ADDR" 0x100

printf 'DDR CSR=0x%08X，测试范围=0xB8000000–0xB80000FF\n' \
    "$((DDR_BASE))"

ddr_clear

set_reg_checked "$DDR_BASE" 0x08 "$TEST_ADDR"
set_reg_checked "$DDR_BASE" 0x0C 0x0
set_reg_checked "$DDR_BASE" 0x10 0x10
set_reg_checked "$DDR_BASE" 0x14 0x5A5A5A5A

run_test "16 字节 FPGA 写入"   0x1 0x02 0
run_test "16 字节 FPGA 读校验" 0x3 0x02 0

# 不修改 DDR，只修改比较模式，应检测到一个单拍事务数据不匹配。
set_reg_checked "$DDR_BASE" 0x14 0xA5A5A5A5
run_test "故意错模式，验证 DATA_ERROR" 0x3 0x26 1

# 不重新写 DDR，恢复正确比较模式。
set_reg_checked "$DDR_BASE" 0x14 0x5A5A5A5A
run_test "恢复正确模式后的读校验" 0x3 0x02 0

set_reg_checked "$DDR_BASE" 0x10 0x100
set_reg_checked "$DDR_BASE" 0x14 0x12345678

run_test "256 字节 FPGA 写入"   0x1 0x02 0
run_test "256 字节 FPGA 读校验" 0x3 0x02 0

printf '\n[ALL PASS] %u 项 FPGA DDR 自测通过。\n' "$PASSED"
printf '最终模式：0xB8000000–0xB80000FF，每个 32 位字为 0x12345678。\n'