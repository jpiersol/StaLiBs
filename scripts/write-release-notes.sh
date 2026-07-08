#!/usr/bin/env bash
set -euo pipefail

tag="${1:?usage: write-release-notes.sh <tag> <zip-name>}"
zip_name="${2:?usage: write-release-notes.sh <tag> <zip-name>}"

tcpdump_tag="$(git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || git -C upstream/tcpdump describe --tags --always)"
tcpdump_commit="$(git -C upstream/tcpdump rev-parse HEAD)"
libpcap_tag="$(git -C upstream/libpcap describe --tags --exact-match 2>/dev/null || git -C upstream/libpcap describe --tags --always)"
libpcap_commit="$(git -C upstream/libpcap rev-parse HEAD)"

cat <<EOF_NOTES
# StaLiBs $tag

Static tcpdump bundle built by GitHub Actions from pinned upstream submodules.

## Contents

- \`bin/tcpdump-linux-x86_64\`
- \`bin/tcpdump-linux-aarch64\`
- \`bin/tcpdump-linux-armv7\`
- build metadata, upstream licenses, and SHA256 checksums

## Upstream pins

- tcpdump: \`$tcpdump_tag\` (\`$tcpdump_commit\`)
- libpcap: \`$libpcap_tag\` (\`$libpcap_commit\`)

## Verification

Download \`$zip_name\`, then run:

\`\`\`sh
gh attestation verify ./$zip_name --repo jpiersol/StaLiBs
unzip $zip_name -d ${zip_name%.zip}
cd ${zip_name%.zip}
sha256sum -c SHA256SUMS
\`\`\`
EOF_NOTES
