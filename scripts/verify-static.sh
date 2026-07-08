#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <binary> [binary ...]" >&2
  exit 64
fi

for bin in "$@"; do
  if [ ! -x "$bin" ]; then
    echo "Not executable: $bin" >&2
    exit 1
  fi

  echo "==> Verifying static binary: $bin"
  file "$bin"

  if readelf -l "$bin" 2>/dev/null | grep -q 'Requesting program interpreter'; then
    echo "ERROR: $bin has a dynamic loader/interpreter" >&2
    exit 1
  fi

  if readelf -d "$bin" 2>/dev/null | grep -q '(NEEDED)'; then
    echo "ERROR: $bin has dynamic library dependencies" >&2
    readelf -d "$bin" >&2 || true
    exit 1
  fi

  if ! file "$bin" | grep -qi 'statically linked'; then
    echo "ERROR: file(1) did not report a statically linked binary" >&2
    exit 1
  fi
done
