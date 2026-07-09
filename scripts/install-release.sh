#!/bin/sh
set -eu

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

bundle_dir="$(CDPATH= cd "$(dirname "$0")" && pwd)"

for tool in tcpdump strace gdb nmap jq; do
  [ -f "$bundle_dir/bin/$tool" ] || fail "missing bundle executable: bin/$tool"
done
[ -d "$bundle_dir/share/nmap" ] || fail "missing Nmap runtime data: share/nmap"

if [ "$(id -u)" -eq 0 ]; then
  prefix=/usr/local
else
  [ -n "${HOME:-}" ] || fail "HOME is not set; cannot choose a user-local install directory"
  prefix="$HOME/.local"
fi

bin_dir="$prefix/bin"
share_dir="$prefix/share"

mkdir -p "$bin_dir" "$share_dir"

for tool in tcpdump strace gdb nmap jq; do
  install -m 0755 "$bundle_dir/bin/$tool" "$bin_dir/$tool"
done

rm -rf "$share_dir/nmap"
cp -R "$bundle_dir/share/nmap" "$share_dir/nmap"

echo "Installed tcpdump, strace, gdb, nmap, and jq in $bin_dir"
echo "Installed Nmap runtime data in $share_dir/nmap"

case ":${PATH:-}:" in
  *":$bin_dir:"*) ;;
  *)
    echo "WARNING: $bin_dir is not in PATH." >&2
    echo "Add this to your shell configuration, then start a new shell:" >&2
    echo "  export PATH=\"$bin_dir:\$PATH\"" >&2
    ;;
esac
