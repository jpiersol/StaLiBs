#!/usr/bin/env bash
set -euo pipefail

tcpdump_repo="https://github.com/the-tcpdump-group/tcpdump.git"
libpcap_repo="https://github.com/the-tcpdump-group/libpcap.git"

latest_tag() {
  local repo="$1"
  local prefix="$2"
  git ls-remote --tags --refs "$repo" "refs/tags/${prefix}-*" |
    awk '{ sub("refs/tags/", "", $2); print $2 }' |
    grep -E "^${prefix}-[0-9]+\.[0-9]+\.[0-9]+$" |
    sort -V |
    tail -n 1
}

latest_tcpdump="$(latest_tag "$tcpdump_repo" tcpdump)"
latest_libpcap="$(latest_tag "$libpcap_repo" libpcap)"

if [[ -z "$latest_tcpdump" || -z "$latest_libpcap" ]]; then
  echo "ERROR: failed to resolve latest upstream tags" >&2
  exit 1
fi

current_tcpdump="$(git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || true)"
current_libpcap="$(git -C upstream/libpcap describe --tags --exact-match 2>/dev/null || true)"

echo "Current tcpdump: ${current_tcpdump:-unknown}"
echo "Latest tcpdump:  $latest_tcpdump"
echo "Current libpcap:  ${current_libpcap:-unknown}"
echo "Latest libpcap:   $latest_libpcap"

git -C upstream/tcpdump fetch --tags --force origin
git -C upstream/libpcap fetch --tags --force origin
git -C upstream/tcpdump checkout -q "$latest_tcpdump"
git -C upstream/libpcap checkout -q "$latest_libpcap"

git add upstream/tcpdump upstream/libpcap

changed=false
if ! git diff --cached --quiet -- upstream/tcpdump upstream/libpcap; then
  changed=true
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "changed=$changed"
    echo "tcpdump_tag=$latest_tcpdump"
    echo "libpcap_tag=$latest_libpcap"
  } >> "$GITHUB_OUTPUT"
fi

if [[ "$changed" == true ]]; then
  echo "Submodules updated."
else
  echo "Submodules already current."
fi
