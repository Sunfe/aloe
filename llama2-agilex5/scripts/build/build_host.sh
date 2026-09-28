#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOST_DIR="${ROOT_DIR}/software/host"
BUILD_DIR="${ROOT_DIR}/build/host"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake "${HOST_DIR}"
cmake --build . -j"$(nproc)"

echo "[OK] host build done: ${BUILD_DIR}"