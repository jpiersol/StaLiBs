#!/usr/bin/env bash
set -euo pipefail

arch="${1:-x86_64}"
build_script="${2:-scripts/build-tcpdump-alpine.sh}"
if [[ -n "${ALPINE_VERSION:-}" ]]; then
  alpine_version="$ALPINE_VERSION"
elif [[ "$build_script" == "scripts/build-ripgrep-alpine.sh" ]]; then
  # ripgrep 15 uses Rust 2024, which needs Cargo >= 1.85. Alpine 3.20
  # ships Cargo 1.78, while 3.22 provides a compatible toolchain.
  alpine_version="3.22"
else
  alpine_version="3.20"
fi

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
  riscv64)
    platform="linux/riscv64"
    ;;
  ppc64le)
    platform="linux/ppc64le"
    ;;
  s390x)
    platform="linux/s390x"
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 64
    ;;
esac

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ ! -f "$repo_root/$build_script" ]; then
  echo "Build script not found: $build_script" >&2
  exit 66
fi

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
  /bin/sh -c "'$build_script' '$arch'"
