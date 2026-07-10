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
  build-base \
  file \
  libcap-dev \
  libcap-static \
  lmdb-dev \
  libuv-dev \
  libuv-static \
  linux-headers \
  meson \
  ninja \
  openssl-dev \
  perl \
  openssl-libs-static \
  pkgconf \
  python3 \
  userspace-rcu-dev \
  userspace-rcu-static

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/bind9" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/bind9" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/bind9" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/dig"
src_dir="$work_dir/src"
build_dir="$work_dir/build"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/bind9" "$src_dir/bind9"
rm -rf "$src_dir/bind9/.git"

bind_src="$src_dir/bind9"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building dig for $arch"
(
  cd "$bind_src"
  meson setup "$build_dir" \
    --buildtype=plain \
    -Db_lto=false \
    -Db_staticpic=true \
    -Dauto-validation=disabled \
    -Dcmocka=disabled \
    -Ddnstap=disabled \
    -Ddoc=disabled \
    -Ddoh=disabled \
    -Dfuzzing=disabled \
    -Dgeoip=disabled \
    -Dgssapi=disabled \
    -Didn=disabled \
    -Djemalloc=disabled \
    -Dleak-detection=disabled \
    -Dline=disabled \
    -Dstats-json=disabled \
    -Dstats-xml=disabled \
    -Dtracing=disabled \
    -Dzlib=disabled \
    -Dprefer_static=true
  ninja -C "$build_dir" -j "$jobs" dig
)

binary="$build_dir/bin/dig"
out="$dist_bin/dig-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" -v >/dev/null

buildinfo="$dist_meta/dig-linux-$arch.buildinfo.txt"
{
  echo "tool=dig"
  echo "artifact=dig-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "bind9_tag=$git_tag"
  echo "bind9_commit=$(git -C "$repo_root/upstream/bind9" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
