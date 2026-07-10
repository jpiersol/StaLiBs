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
  cargo \
  file \
  rust

repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/ripgrep" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/ripgrep" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/ripgrep" describe --tags --always 2>/dev/null || echo unknown)"
work_dir="$repo_root/.build/$arch/ripgrep"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/ripgrep" "$src_dir/ripgrep"
rm -rf "$src_dir/ripgrep/.git"

ripgrep_src="$src_dir/ripgrep"

export CFLAGS="${CFLAGS:--O3 -pipe}"
rustflags="${RUSTFLAGS:--C target-feature=+crt-static}"

printf '%s\n' "==> Building ripgrep for $arch"
(
  cd "$ripgrep_src"
  # Apply static CRT linking only to the final binary. Applying it globally
  # also makes Cargo build scripts static, which crashes under ARMv7 QEMU.
  cargo rustc --release --locked --bin rg -- -C target-feature=+crt-static -C relocation-model=static
)

binary="$ripgrep_src/target/release/rg"
out="$dist_bin/rg-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
printf '%s\n' 'stalibs' | "$out" -qx 'stalibs'
"$out" --version

buildinfo="$dist_meta/rg-linux-$arch.buildinfo.txt"
{
  echo "tool=rg"
  echo "artifact=rg-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "rustflags=$rustflags"
  echo "rustc=$(rustc --version 2>/dev/null || true)"
  echo "ripgrep_tag=$git_tag"
  echo "ripgrep_commit=$(git -C "$repo_root/upstream/ripgrep" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
