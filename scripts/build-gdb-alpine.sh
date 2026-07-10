#!/bin/sh
set -eu

arch="${1:-${STALIBS_ARCH:-unknown}}"
if [ "$arch" = "unknown" ]; then
  echo "Usage: $0 <x86_64|aarch64|armv7|riscv64|ppc64le|s390x>" >&2
  exit 64
fi

case "$arch" in
  x86_64|aarch64|armv7|riscv64|ppc64le|s390x) ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 64
    ;;
esac

apk add --no-cache \
  autoconf \
  automake \
  binutils \
  bison \
  build-base \
  coreutils \
  expat-dev \
  expat-static \
  file \
  flex \
  gawk \
  git \
  gmp-dev \
  linux-headers \
  m4 \
  make \
  mpfr-dev \
  ncurses-dev \
  ncurses-static \
  perl \
  pkgconf \
  python3 \
  readline-dev \
  readline-static \
  texinfo \
  zlib-dev \
  zlib-static

# Optional static development packages for compressed debug sections and faster
# internal hashing.  Missing groups are warnings so a core static GDB build is
# still produced on Alpine architectures where a less common static package is
# unavailable.
apk_add_optional_group() {
  name="$1"
  shift
  if apk add --no-cache "$@"; then
    echo "Installed optional package group: $name"
  else
    echo "WARNING: optional package group unavailable for $arch: $name ($*)" >&2
  fi
}

apk_add_optional_group "LZMA compressed debug sections" xz-dev xz-static
apk_add_optional_group "Zstd compressed debug sections" zstd-dev zstd-static
apk_add_optional_group "xxHash" xxhash-dev xxhash-static

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/gdb" 2>/dev/null || true

gdb_tag="$(git -C "$repo_root/upstream/gdb" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/gdb" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/gdb"
src_dir="$work_dir/src"
build_dir="$work_dir/build"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$build_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/gdb" "$src_dir/gdb"
rm -rf "$src_dir/gdb/.git"

gdb_src="$src_dir/gdb"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
export LDFLAGS="${LDFLAGS:--static}"
export PKG_CONFIG="${PKG_CONFIG:-pkg-config --static}"
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=1

configure_args="--disable-gdb-compile --disable-gdbtk --disable-nls --disable-rpath --disable-shared --disable-source-highlight --disable-werror --enable-static --with-curses --with-expat=yes --with-gmp=/usr --with-lzma=auto --with-mpfr=/usr --with-static-standard-libraries --with-system-readline --with-system-zlib --with-xxhash=auto --with-zstd=auto --without-babeltrace --without-debuginfod --without-guile --without-intel-pt --without-libunwind-ia64 --without-python"

printf '%s\n' "==> Building gdb for $arch"
(
  cd "$build_dir"
  # shellcheck disable=SC2086 # intentional word splitting for configure args
  "$gdb_src/configure" $configure_args
  make -j"$jobs" all-gdb
)

# The GDB link uses libtool, which consumes the compiler-driver -static flag
# without necessarily making the final executable fully static.  Relink the
# final executable with libtool's -all-static option after dependencies are
# built so verify-static.sh can enforce the portable artifact contract.
gdb_final_ldflags="$LDFLAGS -static-libstdc++ -static-libgcc -all-static"
rm -f "$build_dir/gdb/gdb"
make -j"$jobs" -C "$build_dir/gdb" LDFLAGS="$gdb_final_ldflags" gdb

binary="$build_dir/gdb/gdb"
out="$dist_bin/gdb-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" --version
"$out" --nx --batch -ex 'show configuration' >/dev/null

buildinfo="$dist_meta/gdb-linux-$arch.buildinfo.txt"
{
  echo "tool=gdb"
  echo "artifact=gdb-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "cxxflags=$CXXFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "gdb_final_ldflags=$gdb_final_ldflags"
  echo "configure_args=$configure_args"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "cxx=$({ c++ --version 2>/dev/null || true; } | head -n 1)"
  echo "gdb_tag=$gdb_tag"
  echo "gdb_commit=$(git -C "$repo_root/upstream/gdb" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
