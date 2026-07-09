#!/usr/bin/env bash
set -euo pipefail

tag="${1:?usage: write-release-notes.sh <tag>}"

zip_x86_64="stalibs-${tag}-linux-x86_64.zip"
zip_aarch64="stalibs-${tag}-linux-aarch64.zip"
zip_armv7="stalibs-${tag}-linux-armv7.zip"

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

cat <<EOF_NOTES
# StaLiBs $tag

Static platform bundles built by GitHub Actions from pinned upstream submodules.

## Assets

- \`$zip_x86_64\` - x86_64 Linux
- \`$zip_aarch64\` - aarch64 Linux
- \`$zip_armv7\` - ARMv7 hard-float Linux

Each zip contains platform-specific executables at \`bin/tcpdump\`, \`bin/strace\`, \`bin/gdb\`, and \`bin/nmap\`, Nmap runtime data under \`share/nmap\`, build metadata, upstream licenses, and SHA256 checksums.

## Upstream pins

- tcpdump: \`$tcpdump_tag\` (\`$tcpdump_commit\`)
- libpcap: \`$libpcap_tag\` (\`$libpcap_commit\`)
- strace: \`$strace_tag\` (\`$strace_commit\`)
- gdb: \`$gdb_tag\` (\`$gdb_commit\`)
- nmap: \`$nmap_ref\` (\`$nmap_commit\`)

## Verification

Download the zip for your platform, then run:

\`\`\`sh
gh attestation verify ./$zip_x86_64 --repo jpiersol/StaLiBs
unzip $zip_x86_64 -d ${zip_x86_64%.zip}
cd ${zip_x86_64%.zip}
sha256sum -c SHA256SUMS
\`\`\`

Replace \`$zip_x86_64\` with the aarch64 or armv7 asset name as appropriate.
EOF_NOTES
