#!/usr/bin/env bash
#set -euo pipefail
#
#ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
#
#docker run --rm -t \
#  -v "${ROOT_DIR}:${ROOT_DIR}" \
#  -w "${ROOT_DIR}" \
#  -e HTTP_PROXY=http://host.docker.internal:7897 \
#  -e HTTPS_PROXY=http://host.docker.internal:7897 \
#  -e NO_PROXY=localhost,127.0.0.1 \
#  ubuntu:22.04 \
#  bash -lc '
#    set -euo pipefail
#    apt-get update -o Acquire::http::proxy=http://host.docker.internal:7897 -o Acquire::https::proxy=http://host.docker.internal:7897
#    DEBIAN_FRONTEND=noninteractive apt-get install -y \
#      -o Acquire::http::proxy=http://host.docker.internal:7897 \
#      -o Acquire::https::proxy=http://host.docker.internal:7897 \
#      build-essential cmake file \
#      gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
#      libc6-dev-arm64-cross
#    ./scripts/build/build_host_cross.sh
#  '

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_NAME="atk-rk3588-build-env"

if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
  echo "🔧 构建带 apt 代理的镜像..."
  docker build -t "$IMAGE_NAME" - <<EOF
FROM ubuntu:22.04

ENV HTTP_PROXY=http://host.docker.internal:7897
ENV HTTPS_PROXY=http://host.docker.internal:7897

# 强制配置 apt 代理
RUN echo "Acquire::http::proxy \"http://host.docker.internal:7897\";" > /etc/apt/apt.conf.d/99proxy && \
    echo "Acquire::https::proxy \"http://host.docker.internal:7897\";" >> /etc/apt/apt.conf.d/99proxy && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential cmake file \
      gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
      libc6-dev-arm64-cross && \
    rm -rf /var/lib/apt/lists/*
EOF
fi

echo "🚀 开始编译..."
docker run --rm -t \
  -v "${ROOT_DIR}:${ROOT_DIR}" \
  -w "${ROOT_DIR}" \
  "$IMAGE_NAME" \
  ./scripts/build/build_host_cross.sh
