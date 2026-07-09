#!/usr/bin/env bash
set -euo pipefail

tcpdump_repo="https://github.com/the-tcpdump-group/tcpdump.git"
libpcap_repo="https://github.com/the-tcpdump-group/libpcap.git"
strace_repo="https://github.com/strace/strace.git"
gdb_repo="https://github.com/gnutools/binutils-gdb.git"
nmap_repo="https://github.com/nmap/nmap.git"
jq_repo="https://github.com/jqlang/jq.git"

latest_tag() {
  local repo="$1"
  local glob="$2"
  local regex="$3"

  git ls-remote --tags --refs "$repo" "refs/tags/${glob}" |
    awk '{ sub("refs/tags/", "", $2); print $2 }' |
    grep -E "$regex" |
    sort -V |
    tail -n 1
}

latest_tcpdump="$(latest_tag "$tcpdump_repo" 'tcpdump-*' '^tcpdump-[0-9]+\.[0-9]+\.[0-9]+$')"
latest_libpcap="$(latest_tag "$libpcap_repo" 'libpcap-*' '^libpcap-[0-9]+\.[0-9]+\.[0-9]+$')"
latest_strace="$(latest_tag "$strace_repo" 'v*' '^v[0-9]+\.[0-9]+(\.[0-9]+)?$')"
latest_gdb="$(latest_tag "$gdb_repo" 'gdb-*-release' '^gdb-[0-9]+(\.[0-9]+)*-release$')"
latest_nmap="$(git ls-remote "$nmap_repo" refs/heads/master | awk '{ print $1 }')"
latest_jq="$(latest_tag "$jq_repo" 'jq-*' '^jq-[0-9]+\.[0-9]+\.[0-9]+$')"

if [[ -z "$latest_tcpdump" || -z "$latest_libpcap" || -z "$latest_strace" || -z "$latest_gdb" || -z "$latest_nmap" || -z "$latest_jq" ]]; then
  echo "ERROR: failed to resolve latest upstream tags" >&2
  exit 1
fi

current_tcpdump="$(git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || true)"
current_libpcap="$(git -C upstream/libpcap describe --tags --exact-match 2>/dev/null || true)"
current_strace="$(git -C upstream/strace describe --tags --exact-match 2>/dev/null || true)"
current_gdb="$(git -C upstream/gdb describe --tags --exact-match 2>/dev/null || true)"
current_nmap="$(git -C upstream/nmap rev-parse HEAD 2>/dev/null || true)"
current_jq="$(git -C upstream/jq describe --tags --exact-match 2>/dev/null || true)"

echo "Current tcpdump: ${current_tcpdump:-unknown}"
echo "Latest tcpdump:  $latest_tcpdump"
echo "Current libpcap:  ${current_libpcap:-unknown}"
echo "Latest libpcap:   $latest_libpcap"
echo "Current strace:   ${current_strace:-unknown}"
echo "Latest strace:    $latest_strace"
echo "Current gdb:      ${current_gdb:-unknown}"
echo "Latest gdb:       $latest_gdb"
echo "Current nmap:     ${current_nmap:-unknown}"
echo "Latest nmap:      master@$latest_nmap"
echo "Current jq:       ${current_jq:-unknown}"
echo "Latest jq:        $latest_jq"

git -C upstream/tcpdump fetch --tags --force origin
git -C upstream/libpcap fetch --tags --force origin
git -C upstream/strace fetch --tags --force origin
git -C upstream/gdb fetch --tags --force origin
git -C upstream/nmap fetch --depth 1 origin master
git -C upstream/jq fetch --tags --force origin
git -C upstream/tcpdump checkout -q "$latest_tcpdump"
git -C upstream/libpcap checkout -q "$latest_libpcap"
git -C upstream/strace checkout -q "$latest_strace"
git -C upstream/gdb checkout -q "$latest_gdb"
git -C upstream/nmap checkout -q "$latest_nmap"
git -C upstream/jq checkout -q "$latest_jq"

git add upstream/tcpdump upstream/libpcap upstream/strace upstream/gdb upstream/nmap upstream/jq

changed=false
if ! git diff --cached --quiet -- upstream/tcpdump upstream/libpcap upstream/strace upstream/gdb upstream/nmap upstream/jq; then
  changed=true
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "changed=$changed"
    echo "tcpdump_tag=$latest_tcpdump"
    echo "libpcap_tag=$latest_libpcap"
    echo "strace_tag=$latest_strace"
    echo "gdb_tag=$latest_gdb"
    echo "nmap_ref=master@$latest_nmap"
    echo "jq_tag=$latest_jq"
  } >> "$GITHUB_OUTPUT"
fi

if [[ "$changed" == true ]]; then
  echo "Submodules updated."
else
  echo "Submodules already current."
fi
