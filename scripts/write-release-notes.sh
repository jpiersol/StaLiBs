#!/usr/bin/env bash
set -euo pipefail

tag="${1:?usage: write-release-notes.sh <tag>}"
safe_tag="$(printf '%s' "$tag" | tr '/ ' '--')"

zip_x86_64="stalibs-${safe_tag}-linux-x86_64.zip"
zip_aarch64="stalibs-${safe_tag}-linux-aarch64.zip"
zip_armv7="stalibs-${safe_tag}-linux-armv7.zip"
bundle_x86_64="${zip_x86_64%.zip}"

tcpdump_tag="$(git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || git -C upstream/tcpdump describe --tags --always)"
tcpdump_commit="$(git -C upstream/tcpdump rev-parse HEAD)"
libpcap_tag="$(git -C upstream/libpcap describe --tags --exact-match 2>/dev/null || git -C upstream/libpcap describe --tags --always)"
libpcap_commit="$(git -C upstream/libpcap rev-parse HEAD)"
strace_tag="$(git -C upstream/strace describe --tags --exact-match 2>/dev/null || git -C upstream/strace describe --tags --always)"
strace_commit="$(git -C upstream/strace rev-parse HEAD)"
gdb_tag="$(git -C upstream/gdb describe --tags --exact-match 2>/dev/null || git -C upstream/gdb describe --tags --always)"
gdb_commit="$(git -C upstream/gdb rev-parse HEAD)"
nmap_ref="$(git -C upstream/nmap describe --tags --exact-match 2>/dev/null || git -C upstream/nmap describe --tags --always)"
nmap_commit="$(git -C upstream/nmap rev-parse HEAD)"
jq_tag="$(git -C upstream/jq describe --tags --exact-match 2>/dev/null || git -C upstream/jq describe --tags --always)"
jq_commit="$(git -C upstream/jq rev-parse HEAD)"
curl_tag="$(git -C upstream/curl describe --tags --exact-match 2>/dev/null || git -C upstream/curl describe --tags --always)"
curl_commit="$(git -C upstream/curl rev-parse HEAD)"
openssl_tag="$(git -C upstream/openssl describe --tags --exact-match 2>/dev/null || git -C upstream/openssl describe --tags --always)"
openssl_commit="$(git -C upstream/openssl rev-parse HEAD)"

cat <<EOF_NOTES
# StaLiBs $tag

Static platform bundles built by GitHub Actions from pinned upstream submodules.

## Assets

- \`$zip_x86_64\` - x86_64 Linux
- \`$zip_aarch64\` - aarch64 Linux
- \`$zip_armv7\` - ARMv7 hard-float Linux

Each zip extracts into a directory named after the archive without \`.zip\`. That directory contains platform-specific executables at \`bin/tcpdump\`, \`bin/strace\`, \`bin/gdb\`, \`bin/nmap\`, and \`bin/jq\` and \`bin/curl\` and \`bin/openssl\`, Nmap runtime data under \`share/nmap\`, build metadata, upstream licenses, and SHA256 checksums.

## Installation

After extracting the archive, run \`sudo ./install.sh\` to install the tools system-wide in \`/usr/local/bin\`. Without \`sudo\`, \`./install.sh\` installs them in \`~/.local/bin\` and installs Nmap's runtime data in \`~/.local/share/nmap\`.

## Upstream pins

- tcpdump: \`$tcpdump_tag\` (\`$tcpdump_commit\`)
- libpcap: \`$libpcap_tag\` (\`$libpcap_commit\`)
- strace: \`$strace_tag\` (\`$strace_commit\`)
- gdb: \`$gdb_tag\` (\`$gdb_commit\`)
- nmap: \`$nmap_ref\` (\`$nmap_commit\`)
- jq: \`$jq_tag\` (\`$jq_commit\`)
- curl: \`$curl_tag\` (\`$curl_commit\`)
- openssl: \`$openssl_tag\` (\`$openssl_commit\`)

## Verification

Download the zip for your platform, then run:

\`\`\`sh
gh attestation verify ./$zip_x86_64 --repo jpiersol/StaLiBs
unzip $zip_x86_64
cd $bundle_x86_64
sha256sum -c SHA256SUMS
\`\`\`

Replace \`$zip_x86_64\` with the aarch64 or armv7 asset name as appropriate.
EOF_NOTES
