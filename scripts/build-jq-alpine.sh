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
  libtool \
  make \
  pkgconf

jobs="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
repo_root="$(pwd)"
git config --global --add safe.directory "$repo_root" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/jq" 2>/dev/null || true
git config --global --add safe.directory "$repo_root/upstream/jq/vendor/oniguruma" 2>/dev/null || true

git_tag="$(git -C "$repo_root/upstream/jq" describe --tags --exact-match 2>/dev/null || git -C "$repo_root/upstream/jq" describe --tags --always 2>/dev/null || echo unknown)"
jq_version="$(printf '%s' "$git_tag" | sed 's/^jq-//')"
work_dir="$repo_root/.build/$arch/jq"
src_dir="$work_dir/src"
dist_bin="$repo_root/dist/bin"
dist_meta="$repo_root/dist/metadata"

rm -rf "$work_dir"
mkdir -p "$src_dir" "$dist_bin" "$dist_meta"

cp -a "$repo_root/upstream/jq" "$src_dir/jq"
rm -rf "$src_dir/jq/.git"

jq_src="$src_dir/jq"

# The source submodule is checked out without its Git metadata in the isolated
# build tree. jq's Autoconf setup invokes scripts/version, so provide the
# pinned source version explicitly instead of letting it fall back to a hash.
cat > "$jq_src/scripts/version" <<EOF_VERSION
#!/bin/sh
printf '%s\\n' "$jq_version"
EOF_VERSION
chmod 0755 "$jq_src/scripts/version"

export CFLAGS="${CFLAGS:--O3 -pipe}"
export LDFLAGS="${LDFLAGS:--static}"

printf '%s\n' "==> Building jq for $arch"
(
  cd "$jq_src"
  autoreconf -fi
  ./configure \
    --disable-docs \
    --enable-all-static \
    --with-oniguruma=builtin
  make -j"$jobs"
)

binary="$jq_src/jq"
out="$dist_bin/jq-linux-$arch"
cp "$binary" "$out"
strip "$out" || true
chmod 0755 "$out"

"$repo_root/scripts/verify-static.sh" "$out"
printf '%s\n' '{"stalibs":true}' | "$out" -e '.stalibs == true' >/dev/null
"$out" --version

buildinfo="$dist_meta/jq-linux-$arch.buildinfo.txt"
{
  echo "tool=jq"
  echo "artifact=jq-linux-$arch"
  echo "arch=$arch"
  echo "kernel_target=Linux >= 4.4"
  echo "libc=musl"
  echo "alpine_version=$(cat /etc/alpine-release 2>/dev/null || true)"
  echo "cflags=$CFLAGS"
  echo "ldflags=$LDFLAGS"
  echo "cc=$({ cc --version 2>/dev/null || true; } | head -n 1)"
  echo "jq_tag=$git_tag"
  echo "jq_commit=$(git -C "$repo_root/upstream/jq" rev-parse HEAD 2>/dev/null || true)"
  echo "jq_version=$jq_version"
  echo "oniguruma_commit=$(git -C "$repo_root/upstream/jq/vendor/oniguruma" rev-parse HEAD 2>/dev/null || true)"
  echo "repo_commit=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "file=$(file "$out")"
} > "$buildinfo"

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
  chown -R "$HOST_UID:$HOST_GID" "$repo_root/dist" "$repo_root/.build/$arch" 2>/dev/null || true
fi

printf '%s\n' "Built $out"
