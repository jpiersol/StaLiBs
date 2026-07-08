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
  libtool \
  make \
  perl \
  pkgconf

# Optional static development packages.  Missing package groups are warnings so
# that less common optional tcpdump/libpcap features do not block core portable
# builds.  Groups that need libraries include their static packages to avoid
# accidentally detecting a feature that cannot be linked into the final binary.
apk_add_optional_group() {
  name="$1"
  shift
  if apk add --no-cache "$@"; then
    echo "Installed optional package group: $name"
  else
    echo "WARNING: optional package group unavailable for $arch: $name ($*)" >&2
  fi
}

apk_add_optional_group "Bluetooth headers" bluez-dev
apk_add_optional_group "D-Bus" dbus-dev dbus-static expat-dev expat-static
apk_add_optional_group "libcap-ng" libcap-ng-dev libcap-ng-static
apk_add_optional_group "libnl3" libnl3-dev libnl3-static
apk_add_optional_group "libsmi" libsmi-dev libsmi-static
apk_add_optional_group "OpenSSL" openssl-dev openssl-libs-static zlib-dev zlib-static
apk_add_optional_group "RDMA" rdma-core-dev rdma-core-static

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
work_dir="$repo_root/.build/$arch/tcpdump"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/libpcap" "$src_dir/libpcap"
cp -a "$repo_root/upstream/tcpdump" "$src_dir/tcpdump"
rm -f "$src_dir/libpcap/.git" "$src_dir/tcpdump/.git"

libpcap_src="$src_dir/libpcap"
tcpdump_src="$src_dir/tcpdump"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"
export PKG_CONFIG="${PKG_CONFIG:-pkg-config}"
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
export PKG_CONFIG_ALLOW_SYSTEM_LIBS=1

printf '%s\n' "==> Building libpcap for $arch"
(
  cd "$libpcap_src"
  ./autogen.sh
  ./configure \
    --disable-shared \
    --enable-static \
    --enable-remote
  make -j"$jobs"
)

# Include full static dependency hints from libpcap when tcpdump probes and links.
pcap_static_libs=""
if [ -x "$libpcap_src/pcap-config" ]; then
  pcap_static_libs="$($libpcap_src/pcap-config --static --additional-libs 2>/dev/null || true)"
fi

printf '%s\n' "==> Building tcpdump for $arch"
(
  cd "$tcpdump_src"
  ./autogen.sh
  LIBS="$pcap_static_libs ${LIBS:-}" ./configure \
    --enable-smb
  make -j"$jobs" tcpdump
)

binary="$tcpdump_src/tcpdump"
out="$dist_bin/tcpdump-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
"$out" --version
"$out" -h >/dev/null

buildinfo="$dist_meta/tcpdump-linux-$arch.buildinfo.txt"
{
  echo "tool=tcpdump"
  echo "artifact=tcpdump-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "tcpdump_tag=$(git -C "$repo_root/upstream/tcpdump" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/tcpdump" describe --tags --always 2>/dev/null || true)"
  echo "tcpdump_commit=$(git -C "$repo_root/upstream/tcpdump" rev-parse HEAD 2>/dev/null || true)"
  echo "libpcap_tag=$(git -C "$repo_root/upstream/libpcap" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/libpcap" describe --tags --always 2>/dev/null || true)"
  echo "libpcap_commit=$(git -C "$repo_root/upstream/libpcap" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
  echo "pcap_static_libs=$pcap_static_libs"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
