#!/bin/sh
# 板上执行, 需 root (访问 /dev/mem)
set -e
cd "$(dirname "$0")/../sw"
./accel_selftest