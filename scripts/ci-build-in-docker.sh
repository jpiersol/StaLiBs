#!/usr/bin/env bash
set -euo pipefail

arch="${1:-x86_64}"
alpine_version="${ALPINE_VERSION:-3.20}"

case "$arch" in
  x86_64)
    platform="linux/amd64"
    ;;
  aarch64)
    platform="linux/arm64/v8"
    ;;
  armv7)
    platform="linux/arm/v7"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 64
    ;;
esac

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for this build entrypoint." >&2
  exit 127
fi

mkdir -p "$repo_root/dist/bin" "$repo_root/dist/metadata"

docker run --rm \
  --platform "$platform" \
  -e "STALIBS_ARCH=$arch" \
  -e "CFLAGS=${CFLAGS:--O3 -pipe}" \
  -e "ALPINE_VERSION=$alpine_version" \
  -e "HOST_UID=$(id -u)" \
  -e "HOST_GID=$(id -g)" \
  -v "$repo_root:/work" \
  -w /work \
  "alpine:${alpine_version}" \
  /bin/sh -c "scripts/build-tcpdump-alpine.sh '$arch'"
