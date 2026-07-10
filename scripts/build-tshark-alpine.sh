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
  c-ares-dev \
  c-ares-static \
  cmake \
  file \
  flex \
  glib-dev \
  glib-static \
  git \
  libgcrypt-dev \
  libgcrypt-static \
  libgpg-error-dev \
  libgpg-error-static \
  libxml2-dev \
  libxml2-static \
  linux-headers \
  ninja \
  pcre2-dev \
  pkgconf \
  python3 \
  xz-dev \
  xz-static \
  zlib-dev \
  zlib-static

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/wireshark" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/wireshark" describe --tags --match 'v*' --exact-match 2>/dev/null || git -C "$repo_root/upstream/wireshark" describe --tags --match 'v*' --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/tshark"
build_dir="$work_dir/build"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$dist_bin" "$dist_meta"

wireshark_src="$repo_root/upstream/wireshark"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"
export PKG_CONFIG="${PKG_CONFIG:-pkg-config}"
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=1

printf '%s\n' "==> Building tshark for $arch"
cmake -S "$wireshark_src" -B "$build_dir" -G Ninja \
  -DBUILD_wireshark=OFF \
  -DBUILD_tshark=ON \
  -DBUILD_rawshark=OFF \
  -DBUILD_dumpcap=OFF \
  -DBUILD_text2pcap=OFF \
  -DBUILD_mergecap=OFF \
  -DBUILD_reordercap=OFF \
  -DBUILD_editcap=OFF \
  -DBUILD_capinfos=OFF \
  -DBUILD_captype=OFF \
  -DBUILD_randpkt=OFF \
  -DBUILD_dftest=OFF \
  -DBUILD_sharkd=OFF \
  -DBUILD_mmdbresolve=OFF \
  -DBUILD_androiddump=OFF \
  -DBUILD_sshdump=OFF \
  -DBUILD_ciscodump=OFF \
  -DBUILD_dpauxmon=OFF \
  -DBUILD_randpktdump=OFF \
  -DBUILD_wifidump=OFF \
  -DBUILD_sdjournal=OFF \
  -DBUILD_udpdump=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_C_STANDARD_LIBRARIES=-llzma \
  -DUSE_STATIC=ON \
  -DENABLE_PLUGINS=OFF \
  -DENABLE_PCAP=OFF \
  -DENABLE_ZLIB=ON \
  -DENABLE_ZLIBNG=OFF \
  -DENABLE_XXHASH=OFF \
  -DENABLE_MINIZIP=OFF \
  -DENABLE_MINIZIPNG=OFF \
  -DENABLE_LZ4=OFF \
  -DENABLE_BROTLI=OFF \
  -DENABLE_SNAPPY=OFF \
  -DENABLE_ZSTD=OFF \
  -DENABLE_NGHTTP2=OFF \
  -DENABLE_NGHTTP3=OFF \
  -DENABLE_LUA=OFF \
  -DENABLE_SMI=OFF \
  -DENABLE_GNUTLS=OFF \
  -DENABLE_PKCS11=OFF \
  -DENABLE_CAP=OFF \
  -DENABLE_NETLINK=OFF \
  -DENABLE_KERBEROS=OFF \
  -DENABLE_SBC=OFF \
  -DENABLE_SPANDSP=OFF \
  -DENABLE_BCG729=OFF \
  -DENABLE_AMRNB=OFF \
  -DENABLE_AMRWB=OFF \
  -DENABLE_ILBC=OFF \
  -DENABLE_OPUS=OFF \
  -DENABLE_SINSP=OFF \
  -DENABLE_CPUINFO=OFF \
  -DENABLE_WERROR=OFF
ninja -C "$build_dir" -j "$jobs" tshark

binary="$build_dir/run/tshark"
out="$dist_bin/tshark-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" --version

buildinfo="$dist_meta/tshark-linux-$arch.buildinfo.txt"
{
  echo "tool=tshark"
  echo "artifact=tshark-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "wireshark_tag=$git_tag"
  echo "wireshark_commit=$(git -C "$repo_root/upstream/wireshark" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
