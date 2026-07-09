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
  bison \
  build-base \
  file \
  flex \
  git \
  linux-headers \
  m4 \
  make \
  openssl-dev \
  openssl-libs-static \
  perl \
  pkgconf \
  zlib-dev \
  zlib-static

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/nmap" 2>/dev/null || true

nmap_ref="$(git -C "$repo_root/upstream/nmap" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/nmap" describe --tags --always 2>/dev/null || echo unknown)"
nmap_commit="$(git -C "$repo_root/upstream/nmap" rev-parse HEAD 2>/dev/null || true)"
work_dir="$repo_root/.build/$arch/nmap"
src_dir="$work_dir/src"
install_dir="$work_dir/install"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"
dist_share="$repo_root/dist/share/nmap"

rm -rf "$work_dir" "$dist_share"
mkdir -p "$src_dir" "$install_dir" "$dist_bin" "$dist_meta" "$repo_root/dist/share"

cp -a "$repo_root/upstream/nmap" "$src_dir/nmap"
rm -rf "$src_dir/nmap/.git"

nmap_src="$src_dir/nmap"

nmap_version="$(awk '/#define NMAP_MAJOR/ { major=$3 } /#define NMAP_MINOR/ { minor=$3 } /#define NMAP_SPECIAL/ { special=$3 } END { gsub(/\"/, "", special); if (major && minor) print major "." minor special; else print "unknown" }' "$nmap_src/nmap.h")"
openssl_static_libs="$(pkg-config --static --libs openssl 2>/dev/null || echo '-lssl -lcrypto -lz')"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
export LDFLAGS="${LDFLAGS:--static}"
export LIBS="${LIBS:-} $openssl_static_libs -pthread"
export PKG_CONFIG="${PKG_CONFIG:-pkg-config --static}"
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=1

configure_args="--prefix=/usr --disable-nls --with-libdnet=included --with-liblinear=included --with-liblua=included --with-libpcap=included --with-libpcre=included --with-libz=included --with-openssl=/usr --without-libssh2 --without-ncat --without-ndiff --without-nping --without-zenmap"

printf '%s\n' "==> Building nmap for $arch"
(
  cd "$nmap_src"
  # shellcheck disable=SC2086 # intentional word splitting for configure args
  ./configure $configure_args
  make -j"$jobs" nmap
  make install-nmap install-nse DESTDIR="$install_dir" STRIP=:
)

binary="$install_dir/usr/bin/nmap"
out="$dist_bin/nmap-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

cp -a "$install_dir/usr/share/nmap" "$dist_share"

"$repo_root/scripts/verify-static.sh" "$out"
test -f "$dist_share/nmap-services"
test -f "$dist_share/scripts/script.db"
"$out" --datadir "$dist_share" --version

buildinfo="$dist_meta/nmap-linux-$arch.buildinfo.txt"
{
  echo "tool=nmap"
  echo "artifact=nmap-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "cxxflags=$CXXFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "libs=$LIBS"
  echo "configure_args=$configure_args"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "cxx=$({ c++ --version 2>/dev/null || true; } | head -n 1)"
  echo "nmap_version=$nmap_version"
  echo "nmap_ref=$nmap_ref"
  echo "nmap_commit=$nmap_commit"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
