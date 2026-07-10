#!/bin/sh
set -eu

arch="${1:-${STALIBS_ARCH:-unknown}}"
if [ "$arch" = "unknown" ]; then
  echo "Usage: $0 <x86_64|aarch64|armv7>" >&2
  exit 64
fi

case "$arch" in
  x86_64)
    openssl_target=linux-x86_64
    ;;
  aarch64)
    openssl_target=linux-aarch64
    ;;
  armv7)
    openssl_target=linux-armv4
    ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 64
    ;;
esac

apk add --no-cache \
  binutils \
  build-base \
  file \
  linux-headers \
  make \
  perl \
  perl-text-template

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/openssl" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/openssl" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/openssl" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/openssl"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/openssl" "$src_dir/openssl"
rm -rf "$src_dir/openssl/.git"

openssl_src="$src_dir/openssl"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building OpenSSL for $arch"
(
  cd "$openssl_src"
  ./Configure "$openssl_target" no-shared no-tests --prefix=/usr --openssldir=/etc/ssl
  make -j"$jobs" build_sw
)

binary="$openssl_src/apps/openssl"
out="$dist_bin/openssl-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" version

buildinfo="$dist_meta/openssl-linux-$arch.buildinfo.txt"
{
  echo "tool=openssl"
  echo "artifact=openssl-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "openssl_tag=$git_tag"
  echo "openssl_commit=$(git -C "$repo_root/upstream/openssl" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
