#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 2 || "$#" -gt 4 ]]; then
  echo "Usage: $0 <x86_64|aarch64|armv7> <version> [input-root] [output-dir]" >&2
  exit 64
fi

arch="$1"
version="$2"
input_root="${3:-package-root}"
out_dir="${4:-dist}"

case "$arch" in
  x86_64|aarch64|armv7) ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 64
    ;;
esac

safe_version="$(printf '%s' "$version" | tr '/ ' '--')"
zip_name="stalibs-${safe_version}-linux-${arch}.zip"
bundle_name="${zip_name%.zip}"
zip_path="${out_dir}/${zip_name}"
zip_abs_path="$(pwd)/${zip_path}"
staging_parent=".build/package/${safe_version}/linux-${arch}"
staging_dir="${staging_parent}/${bundle_name}"

find_tool_binary() {
  local tool="$1"
  local -a candidates=(
    "${input_root}/${tool}/bin/${tool}"
    "${input_root}/${tool}/artifact-root/bin/${tool}"
    "${input_root}/bin/${tool}"
    "${input_root}/artifact-root/bin/${tool}"
    "${input_root}/bin/${tool}-linux-${arch}"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Missing executable artifact for ${tool}. Expected ${input_root}/${tool}/bin/${tool}" >&2
  return 1
}

find_tool_buildinfo() {
  local tool="$1"
  local -a candidates=(
    "${input_root}/${tool}/metadata/${tool}.buildinfo.txt"
    "${input_root}/${tool}/artifact-root/metadata/${tool}.buildinfo.txt"
    "${input_root}/metadata/${tool}.buildinfo.txt"
    "${input_root}/artifact-root/metadata/${tool}.buildinfo.txt"
    "${input_root}/metadata/${tool}-linux-${arch}.buildinfo.txt"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Missing build metadata artifact for ${tool}. Expected ${input_root}/${tool}/metadata/${tool}.buildinfo.txt" >&2
  return 1
}

tcpdump_binary="$(find_tool_binary tcpdump)"
tcpdump_buildinfo="$(find_tool_buildinfo tcpdump)"
strace_binary="$(find_tool_binary strace)"
strace_buildinfo="$(find_tool_buildinfo strace)"
gdb_binary="$(find_tool_binary gdb)"
gdb_buildinfo="$(find_tool_buildinfo gdb)"
nmap_binary="$(find_tool_binary nmap)"
nmap_buildinfo="$(find_tool_buildinfo nmap)"

find_nmap_data() {
  local -a candidates=(
    "${input_root}/nmap/share/nmap"
    "${input_root}/nmap/artifact-root/share/nmap"
    "${input_root}/share/nmap"
    "${input_root}/artifact-root/share/nmap"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Missing nmap runtime data artifact. Expected ${input_root}/nmap/share/nmap" >&2
  return 1
}

nmap_data="$(find_nmap_data)"

rm -rf "$staging_dir"
mkdir -p "$staging_dir/bin" "$staging_dir/metadata" "$staging_dir/licenses" "$staging_dir/share" "$out_dir"

cp "$tcpdump_binary" "$staging_dir/bin/tcpdump"
cp "$tcpdump_buildinfo" "$staging_dir/metadata/tcpdump.buildinfo.txt"
cp "$strace_binary" "$staging_dir/bin/strace"
cp "$strace_buildinfo" "$staging_dir/metadata/strace.buildinfo.txt"
cp "$gdb_binary" "$staging_dir/bin/gdb"
cp "$gdb_buildinfo" "$staging_dir/metadata/gdb.buildinfo.txt"
cp "$nmap_binary" "$staging_dir/bin/nmap"
cp "$nmap_buildinfo" "$staging_dir/metadata/nmap.buildinfo.txt"
cp -a "$nmap_data" "$staging_dir/share/nmap"
cp scripts/install-release.sh "$staging_dir/install.sh"
chmod 0755 "$staging_dir/bin/tcpdump" "$staging_dir/bin/strace" "$staging_dir/bin/gdb" "$staging_dir/bin/nmap" "$staging_dir/install.sh"

cp upstream/tcpdump/LICENSE "$staging_dir/licenses/tcpdump-LICENSE.txt"
cp upstream/libpcap/LICENSE "$staging_dir/licenses/libpcap-LICENSE.txt"
cp upstream/strace/COPYING "$staging_dir/licenses/strace-COPYING.txt"
cp upstream/strace/LGPL-2.1-or-later "$staging_dir/licenses/strace-LGPL-2.1-or-later.txt"
cp upstream/strace/bundled/linux/COPYING "$staging_dir/licenses/strace-bundled-linux-COPYING.txt"
cp upstream/gdb/COPYING "$staging_dir/licenses/gdb-COPYING.txt"
cp upstream/gdb/COPYING.LIB "$staging_dir/licenses/gdb-COPYING.LIB.txt"
cp upstream/gdb/COPYING3 "$staging_dir/licenses/gdb-COPYING3.txt"
cp upstream/gdb/COPYING3.LIB "$staging_dir/licenses/gdb-COPYING3.LIB.txt"
cp upstream/gdb/gdb/COPYING "$staging_dir/licenses/gdb-gdb-COPYING.txt"
cp upstream/gdb/readline/readline/COPYING "$staging_dir/licenses/gdb-readline-COPYING.txt"
cp upstream/nmap/LICENSE "$staging_dir/licenses/nmap-LICENSE.txt"
cp upstream/nmap/libdnet-stripped/LICENSE "$staging_dir/licenses/nmap-libdnet-LICENSE.txt"
cp upstream/nmap/liblinear/COPYRIGHT "$staging_dir/licenses/nmap-liblinear-COPYRIGHT.txt"
cp upstream/nmap/liblua/lua.h "$staging_dir/licenses/nmap-liblua-lua.h.txt"
cp upstream/nmap/libpcap/LICENSE "$staging_dir/licenses/nmap-libpcap-LICENSE.txt"
cp upstream/nmap/libpcre/LICENCE.md "$staging_dir/licenses/nmap-libpcre-LICENCE.md"
cp upstream/nmap/libz/LICENSE "$staging_dir/licenses/nmap-libz-LICENSE.txt"
cp LICENSE "$staging_dir/LICENSE.txt"
cp LICENSES.md "$staging_dir/LICENSES.md"

cat > "$staging_dir/README.txt" <<EOF_README
StaLiBs static binary bundle

Source repository: https://github.com/jpiersol/StaLiBs
Git ref: ${GITHUB_REF_NAME:-unknown}
Git sha: ${GITHUB_SHA:-unknown}
Target platform: linux-${arch}
Kernel target: Linux >= 4.4
Executables:
  bin/tcpdump
  bin/strace
  bin/gdb
  bin/nmap
Runtime data:
  share/nmap

Install the tools:
  sudo ./install.sh  # system-wide: /usr/local/bin
  ./install.sh       # user-local: ~/.local/bin

Verify provenance:
  gh attestation verify ./${zip_name} --repo jpiersol/StaLiBs

Verify bundle checksums after unzipping:
  sha256sum -c SHA256SUMS
EOF_README

(
  cd "$staging_dir"
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

(
  cd "$staging_parent"
  zip -r "$zip_abs_path" "$bundle_name"
)

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "zip_name=$zip_name"
    echo "zip_path=$zip_path"
  } >> "$GITHUB_OUTPUT"
fi

printf '%s\n' "$zip_path"
