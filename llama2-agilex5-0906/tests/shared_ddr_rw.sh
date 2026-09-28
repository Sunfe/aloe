#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# 文件：shared_ddr_rw.sh
#
# 功能：
#   对 shared_ddr_rw_tool 提供 Bash 安全包装。
#
# 支持操作：
#   fill  ：向共享 DDR 写入统一的 32 位模式；
#   check ：检查共享 DDR 中的 32 位数据模式。
#
# 示例：
#   sudo ./shared_ddr_rw.sh fill \
#       0xBA000000 0x10000 0xA5A5A5A5
#
#   sudo ./shared_ddr_rw.sh check \
#       0xBA000000 0x10000 0xA5A5A5A5
#
# 安全检查：
#   1. 检查 root 权限；
#   2. 检查 mem=896M 启动参数；
#   3. 检查地址和长度的 4 字节对齐；
#   4. 检查访问范围是否位于 0xB8000000-0xBFFFFFFF；
#   5. 调用 shared_ddr_rw_tool 完成实际 /dev/mem 访问。
#
# 本脚本的性质：
#   这是共享 DDR 工具的包装入口，不是完整测试。
#   它不会启动 DDR Test Master，也不会验证 HPS-FPGA 双向交换。
#
# 完整的 HPS-FPGA 交换测试：
#   请运行 test_ddr_hps_fpga_exchange.sh。
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/shared_ddr_rw_tool"

SHARED_BEGIN=0xB8000000
SHARED_END=0xC0000000

fail() {
    printf '[FAIL] %s\n' "$*" >&2
    exit 1
}

usage() {
    printf '用法：\n' >&2
    printf '  sudo bash %s fill  <phys_addr> <bytes> <pattern>\n' "$0" >&2
    printf '  sudo bash %s check <phys_addr> <bytes> <pattern>\n' "$0" >&2
    exit 2
}

# 当前板级测试只接受 uint32 范围的非负整数。
# 十六进制最多 8 位；十进制最多 10 位。
# 先校验文本，再进行算术运算。
parse_u32() {
    local text="$1"
    local output_name="$2"
    local n

    if [[ "$text" =~ ^0[xX][[:xdigit:]]{1,8}$ ]]; then
        n=$((16#${text:2}))
    elif [[ "$text" =~ ^[0-9]{1,10}$ ]]; then
        n=$((10#$text))
    else
        fail "非法数值：$text"
    fi

    (( n >= 0 && n <= 0xFFFFFFFF )) ||
        fail "数值超出 32 位范围：$text"

    printf -v "$output_name" '%u' "$n"
}

[[ $# -eq 4 ]] || usage
[[ $EUID -eq 0 ]] || fail "请使用 sudo bash \"$0\" ... 运行。"

OP="$1"
case "$OP" in
    fill|check) ;;
    *) usage ;;
esac

parse_u32 "$2" ADDR
parse_u32 "$3" BYTES
parse_u32 "$4" PATTERN

(( BYTES > 0 )) || fail "长度必须大于 0。"

(( (ADDR & 3) == 0 && (BYTES & 3) == 0 )) ||
    fail "地址和长度必须为 4 字节对齐。"

(( ADDR >= SHARED_BEGIN && ADDR < SHARED_END )) ||
    fail "地址必须位于 0xB8000000–0xBFFFFFFF。"

# 用减法检查边界，避免直接相加可能造成的溢出。
(( BYTES <= SHARED_END - ADDR )) ||
    fail "访问范围超出共享 DDR 结束地址 0xC0000000。"

[[ -r /proc/cmdline ]] || fail "无法读取 /proc/cmdline。"
CMDLINE="$(</proc/cmdline)"

[[ " $CMDLINE " == *" mem=896M "* ]] ||
    fail "当前启动参数不含 mem=896M，停止访问。"

[[ -x "$TOOL" ]] ||
    fail "找不到可执行程序：$TOOL；请先编译 shared_mem_tool.c。"

printf '操作=%s，范围=0x%08X–0x%08X，模式=0x%08X\n' \
    "$OP" "$ADDR" "$((ADDR + BYTES - 1))" "$PATTERN"

# 调用已验证的 C 工具，原样保留其退出状态。
# 本脚本不启动 FPGA，也不自动判断 FPGA 是否仍在访问该区域。
exec "$TOOL" "$OP" "$ADDR" "$BYTES" "$PATTERN"