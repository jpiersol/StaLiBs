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
  binutils \
  build-base \
  file \
  libtool \
  ncurses-dev \
  ncurses-static \
  pkgconf

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/mtr" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/mtr" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/mtr" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/mtr"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/mtr" "$src_dir/mtr"
rm -rf "$src_dir/mtr/.git"

mtr_src="$src_dir/mtr"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building mtr for $arch"
(
  cd "$mtr_src"
  ./bootstrap.sh
  ./configure \
    --without-gtk \
    --without-jansson
  make -j"$jobs"
)

binary="$mtr_src/mtr"
out="$dist_bin/mtr-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" --version

buildinfo="$dist_meta/mtr-linux-$arch.buildinfo.txt"
{
  echo "tool=mtr"
  echo "artifact=mtr-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "mtr_tag=$git_tag"
  echo "mtr_commit=$(git -C "$repo_root/upstream/mtr" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
