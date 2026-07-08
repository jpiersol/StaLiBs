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
zip_path="${out_dir}/${zip_name}"
zip_abs_path="$(pwd)/${zip_path}"
staging_dir=".build/package/${safe_version}/linux-${arch}"

binary="${input_root}/bin/tcpdump"
buildinfo="${input_root}/metadata/tcpdump.buildinfo.txt"

# Local builds write architecture-qualified files to dist/ so multiple targets can
# coexist.  CI stages the selected target to the original executable name before
# packaging, and release zips always contain bin/tcpdump.
if [[ ! -x "$binary" && -x "${input_root}/artifact-root/bin/tcpdump" ]]; then
  binary="${input_root}/artifact-root/bin/tcpdump"
fi

if [[ ! -x "$binary" && -x "${input_root}/bin/tcpdump-linux-${arch}" ]]; then
  binary="${input_root}/bin/tcpdump-linux-${arch}"
fi

if [[ ! -f "$buildinfo" && -f "${input_root}/artifact-root/metadata/tcpdump.buildinfo.txt" ]]; then
  buildinfo="${input_root}/artifact-root/metadata/tcpdump.buildinfo.txt"
fi

if [[ ! -f "$buildinfo" && -f "${input_root}/metadata/tcpdump-linux-${arch}.buildinfo.txt" ]]; then
  buildinfo="${input_root}/metadata/tcpdump-linux-${arch}.buildinfo.txt"
fi

if [[ ! -x "$binary" ]]; then
  echo "Missing executable artifact. Expected ${input_root}/bin/tcpdump" >&2
  exit 1
fi

if [[ ! -f "$buildinfo" ]]; then
  echo "Missing build metadata artifact. Expected ${input_root}/metadata/tcpdump.buildinfo.txt" >&2
  exit 1
fi

rm -rf "$staging_dir"
mkdir -p "$staging_dir/bin" "$staging_dir/metadata" "$staging_dir/licenses" "$out_dir"

cp "$binary" "$staging_dir/bin/tcpdump"
cp "$buildinfo" "$staging_dir/metadata/tcpdump.buildinfo.txt"
cp upstream/tcpdump/LICENSE "$staging_dir/licenses/tcpdump-LICENSE.txt"
cp upstream/libpcap/LICENSE "$staging_dir/licenses/libpcap-LICENSE.txt"
cp LICENSE "$staging_dir/LICENSE.txt"
cp LICENSES.md "$staging_dir/LICENSES.md"

cat > "$staging_dir/README.txt" <<EOF_README
StaLiBs static tcpdump bundle

Source repository: https://github.com/jpiersol/StaLiBs
Git ref: ${GITHUB_REF_NAME:-unknown}
Git sha: ${GITHUB_SHA:-unknown}
Target platform: linux-${arch}
Kernel target: Linux >= 4.4
Executable: bin/tcpdump

Verify provenance:
  gh attestation verify ./${zip_name} --repo jpiersol/StaLiBs

Verify bundle checksums after unzipping:
  sha256sum -c SHA256SUMS
EOF_README

(
  cd "$staging_dir"
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
  zip -r "$zip_abs_path" .
)

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "zip_name=$zip_name"
    echo "zip_path=$zip_path"
  } >> "$GITHUB_OUTPUT"
fi

printf '%s\n' "$zip_path"
