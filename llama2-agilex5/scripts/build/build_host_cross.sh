#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/host-aarch64"
SRC_DIR="${ROOT_DIR}/software/host"
TC_FILE="${ROOT_DIR}/cmake/toolchains/aarch64-linux-gnu.cmake"

mkdir -p "${BUILD_DIR}"

cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
  -DCMAKE_TOOLCHAIN_FILE="${TC_FILE}" \
  -DCMAKE_BUILD_TYPE=Release

cmake --build "${BUILD_DIR}" -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)"

echo "[OK] cross build done: ${BUILD_DIR}"
file "${BUILD_DIR}/test_fpga_gemv" || true
