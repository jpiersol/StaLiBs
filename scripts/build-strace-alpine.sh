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
  coreutils \
  file \
  gawk \
  git \
  linux-headers \
  make \
  perl \
  pkgconf

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/strace" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/strace" describe --tags --always 2>/dev/null || echo unknown)"
strace_version="$(printf '%s' "$git_tag" | sed 's/^v//')"
work_dir="$repo_root/.build/$arch/strace"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/strace" "$src_dir/strace"
rm -f "$src_dir/strace/.git"

strace_src="$src_dir/strace"

# strace's git bootstrap scripts derive version/date metadata from git when
# these files are absent.  The copied build tree intentionally has no .git, and
# Alpine's BusyBox date is not GNU-compatible, so provide tarball-style metadata
# explicitly for a deterministic source-submodule build.
printf '%s\n' "$strace_version" > "$strace_src/.tarball-version"
date -u +%Y > "$strace_src/.year"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building strace for $arch"
(
  cd "$strace_src"
  ./bootstrap
  ./configure \
    --enable-gcc-Werror=no \
    --enable-mpers=check
  make -j"$jobs" -C src all-am
)

binary="$strace_src/src/strace"
out="$dist_bin/strace-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" -V

buildinfo="$dist_meta/strace-linux-$arch.buildinfo.txt"
{
  echo "tool=strace"
  echo "artifact=strace-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "strace_tag=$git_tag"
  echo "strace_commit=$(git -C "$repo_root/upstream/strace" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
