#!/bin/sh
set -eu

arch="${1:-${STALIBS_ARCH:-unknown}}"
if [ "$arch" = "unknown" ]; then
  echo "Usage: $0 <x86_64|aarch64|armv7>" >&2
  exit 64
fi

case "$arch" in
  x86_64|aarch64|armv7) ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 64
    ;;
esac

apk add --no-cache \
  binutils \
  bison \
  build-base \
  file \
  flex \
  linux-headers \
  make \
  pkgconf

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/iproute2" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/iproute2" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/iproute2" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/iproute2"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/iproute2" "$src_dir/iproute2"
rm -rf "$src_dir/iproute2/.git"

iproute2_src="$src_dir/iproute2"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building iproute2 tools for $arch"
(
  cd "$iproute2_src"
  make -j"$jobs" SHARED_LIBS=n
)

copy_binary() {
  tool="$1"
  binary="$2"
  out="$dist_bin/$tool-linux-$arch"

  cp "$binary" "$out"
  strip "$out" || true
  chmod 0755 "$out"
  "$repo_root/scripts/verify-static.sh" "$out"

  buildinfo="$dist_meta/$tool-linux-$arch.buildinfo.txt"
  {
    echo "tool=$tool"
    echo "artifact=$tool-linux-$arch"
    echo "arch=$arch"
    echo "kernel_target=Linux >= 4.4"
    echo "libc=musl"
    echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
    echo "cflags=$CFLAGS"
    echo "ldflags=$LDFLAGS"
    echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
    echo "iproute2_tag=$git_tag"
    echo "iproute2_commit=$(git -C "$repo_root/upstream/iproute2" rev-parse HEAD 2>/dev/null || true)"
    echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
    echo "file=$(file "$out")"
  } > "$buildinfo"
}

copy_binary ip "$iproute2_src/ip/ip"
copy_binary ss "$iproute2_src/misc/ss"
copy_binary bridge "$iproute2_src/bridge/bridge"
copy_binary tc "$iproute2_src/tc/tc"

"$dist_bin/ip-linux-$arch" -Version
"$dist_bin/ss-linux-$arch" -V
"$dist_bin/bridge-linux-$arch" -V
"$dist_bin/tc-linux-$arch" -V

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built iproute2 tools in $dist_bin"
