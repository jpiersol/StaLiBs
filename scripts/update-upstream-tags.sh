#!/usr/bin/env bash
set -euo pipefail

tcpdump_repo="https://github.com/the-tcpdump-group/tcpdump.git"
libpcap_repo="https://github.com/the-tcpdump-group/libpcap.git"
strace_repo="https://github.com/strace/strace.git"
gdb_repo="https://github.com/gnutools/binutils-gdb.git"
nmap_repo="https://github.com/nmap/nmap.git"
jq_repo="https://github.com/jqlang/jq.git"
curl_repo="https://github.com/curl/curl.git"
openssl_repo="https://github.com/openssl/openssl.git"
socat_repo="https://repo.or.cz/socat.git"
bind9_repo="https://github.com/isc-projects/bind9.git"
mtr_repo="https://github.com/traviscross/mtr.git"
lsof_repo="https://github.com/lsof-org/lsof.git"
iproute2_repo="https://github.com/iproute2/iproute2.git"
wireshark_repo="https://github.com/wireshark/wireshark.git"
ripgrep_repo="https://github.com/BurntSushi/ripgrep.git"

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
latest_curl="$(latest_tag "$curl_repo" 'curl-*' '^curl-[0-9]+_[0-9]+_[0-9]+$')"
latest_openssl="$(latest_tag "$openssl_repo" 'openssl-*' '^openssl-[0-9]+\.[0-9]+\.[0-9]+$')"
latest_socat="$(latest_tag "$socat_repo" 'tag-*' '^tag-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')"
latest_bind9="$(latest_tag "$bind9_repo" 'v*' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
latest_mtr="$(latest_tag "$mtr_repo" 'v*' '^v[0-9]+\.[0-9]+$')"
latest_lsof="$(latest_tag "$lsof_repo" '*' '^[0-9]+\.[0-9]+\.[0-9]+$')"
latest_iproute2="$(latest_tag "$iproute2_repo" 'v*' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
latest_wireshark="$(latest_tag "$wireshark_repo" 'v*' '^v[0-9]+\.[0-9]+\.[0-9]+$')"
latest_ripgrep="$(latest_tag "$ripgrep_repo" '*' '^[0-9]+\.[0-9]+\.[0-9]+$')"

if [[ -z "$latest_tcpdump" || -z "$latest_libpcap" || -z "$latest_strace" || -z "$latest_gdb" || -z "$latest_nmap" || -z "$latest_jq" || -z "$latest_curl" || -z "$latest_openssl" || -z "$latest_socat" || -z "$latest_bind9" || -z "$latest_mtr" || -z "$latest_lsof" || -z "$latest_iproute2" || -z "$latest_wireshark" || -z "$latest_ripgrep" ]]; then
  echo "ERROR: failed to resolve latest upstream tags" >&2
  exit 1
fi

current_tcpdump="$(git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || true)"
current_libpcap="$(git -C upstream/libpcap describe --tags --exact-match 2>/dev/null || true)"
current_strace="$(git -C upstream/strace describe --tags --exact-match 2>/dev/null || true)"
current_gdb="$(git -C upstream/gdb describe --tags --exact-match 2>/dev/null || true)"
current_nmap="$(git -C upstream/nmap rev-parse HEAD 2>/dev/null || true)"
current_jq="$(git -C upstream/jq describe --tags --exact-match 2>/dev/null || true)"
current_curl="$(git -C upstream/curl describe --tags --exact-match 2>/dev/null || true)"
current_openssl="$(git -C upstream/openssl describe --tags --exact-match 2>/dev/null || true)"
current_socat="$(git -C upstream/socat describe --tags --exact-match 2>/dev/null || true)"
current_bind9="$(git -C upstream/bind9 describe --tags --exact-match 2>/dev/null || true)"
current_mtr="$(git -C upstream/mtr describe --tags --exact-match 2>/dev/null || true)"
current_lsof="$(git -C upstream/lsof describe --tags --exact-match 2>/dev/null || true)"
current_iproute2="$(git -C upstream/iproute2 describe --tags --exact-match 2>/dev/null || true)"
current_wireshark="$(git -C upstream/wireshark describe --tags --match 'v*' --exact-match 2>/dev/null || true)"
current_ripgrep="$(git -C upstream/ripgrep describe --tags --exact-match 2>/dev/null || true)"

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
echo "Current curl:     ${current_curl:-unknown}"
echo "Latest curl:      $latest_curl"
echo "Current OpenSSL:  ${current_openssl:-unknown}"
echo "Latest OpenSSL:   $latest_openssl"
echo "Current socat:    ${current_socat:-unknown}"
echo "Latest socat:     $latest_socat"
echo "Current BIND:     ${current_bind9:-unknown}"
echo "Latest BIND:      $latest_bind9"
echo "Current mtr:      ${current_mtr:-unknown}"
echo "Latest mtr:       $latest_mtr"
echo "Current lsof:     ${current_lsof:-unknown}"
echo "Latest lsof:      $latest_lsof"
echo "Current iproute2: ${current_iproute2:-unknown}"
echo "Latest iproute2:  $latest_iproute2"
echo "Current Wireshark: ${current_wireshark:-unknown}"
echo "Latest Wireshark:  $latest_wireshark"
echo "Current ripgrep:  ${current_ripgrep:-unknown}"
echo "Latest ripgrep:   $latest_ripgrep"

git -C upstream/tcpdump fetch --tags --force origin
git -C upstream/libpcap fetch --tags --force origin
git -C upstream/strace fetch --tags --force origin
git -C upstream/gdb fetch --tags --force origin
git -C upstream/nmap fetch --depth 1 origin master
git -C upstream/jq fetch --tags --force origin
git -C upstream/curl fetch --tags --force origin
git -C upstream/openssl fetch --tags --force origin
git -C upstream/socat fetch --tags --force origin
git -C upstream/bind9 fetch --tags --force origin
git -C upstream/mtr fetch --tags --force origin
git -C upstream/lsof fetch --tags --force origin
git -C upstream/iproute2 fetch --tags --force origin
git -C upstream/wireshark fetch --tags --force origin
git -C upstream/ripgrep fetch --tags --force origin
git -C upstream/tcpdump checkout -q "$latest_tcpdump"
git -C upstream/libpcap checkout -q "$latest_libpcap"
git -C upstream/strace checkout -q "$latest_strace"
git -C upstream/gdb checkout -q "$latest_gdb"
git -C upstream/nmap checkout -q "$latest_nmap"
git -C upstream/jq checkout -q "$latest_jq"
git -C upstream/curl checkout -q "$latest_curl"
git -C upstream/openssl checkout -q "$latest_openssl"
git -C upstream/socat checkout -q "$latest_socat"
git -C upstream/bind9 checkout -q "$latest_bind9"
git -C upstream/mtr checkout -q "$latest_mtr"
git -C upstream/lsof checkout -q "$latest_lsof"
git -C upstream/iproute2 checkout -q "$latest_iproute2"
git -C upstream/wireshark checkout -q "$latest_wireshark"
git -C upstream/ripgrep checkout -q "$latest_ripgrep"

git add upstream/tcpdump upstream/libpcap upstream/strace upstream/gdb upstream/nmap upstream/jq upstream/curl upstream/openssl upstream/socat upstream/bind9 upstream/mtr upstream/lsof upstream/iproute2 upstream/wireshark upstream/ripgrep

changed=false
if ! git diff --cached --quiet -- upstream/tcpdump upstream/libpcap upstream/strace upstream/gdb upstream/nmap upstream/jq upstream/curl upstream/openssl upstream/socat upstream/bind9 upstream/mtr upstream/lsof upstream/iproute2 upstream/wireshark upstream/ripgrep; then
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
    echo "curl_tag=$latest_curl"
    echo "openssl_tag=$latest_openssl"
    echo "socat_tag=$latest_socat"
    echo "bind9_tag=$latest_bind9"
    echo "mtr_tag=$latest_mtr"
    echo "lsof_tag=$latest_lsof"
    echo "iproute2_tag=$latest_iproute2"
    echo "wireshark_tag=$latest_wireshark"
    echo "ripgrep_tag=$latest_ripgrep"
  } >> "$GITHUB_OUTPUT"
fi

if [[ "$changed" == true ]]; then
  echo "Submodules updated."
else
  echo "Submodules already current."
fi
