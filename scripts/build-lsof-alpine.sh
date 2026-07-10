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
  autoconf \
  automake \
  bash \
  binutils \
  build-base \
  file \
  linux-headers \
  libtool \
  make

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/lsof" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/lsof" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/lsof" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/lsof"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/lsof" "$src_dir/lsof"
rm -rf "$src_dir/lsof/.git"

lsof_src="$src_dir/lsof"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building lsof for $arch"
(
  cd "$lsof_src"
  ./Configure -n linux
  sed -i 's/^CFGL=/CFGL= -static /' Makefile
  make -j"$jobs"
)

binary="$lsof_src/lsof"
out="$dist_bin/lsof-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" -v

buildinfo="$dist_meta/lsof-linux-$arch.buildinfo.txt"
{
  echo "tool=lsof"
  echo "artifact=lsof-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "lsof_tag=$git_tag"
  echo "lsof_commit=$(git -C "$repo_root/upstream/lsof" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
