#!/usr/bin/env bash
set -euo pipefail

tag="${1:?usage: validate-release-tag.sh <tcpdump-x.y.z>}"

if [[ ! "$tag" =~ ^tcpdump-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: release tag must be an official stable tcpdump tag such as tcpdump-4.99.6" >&2
  exit 64
fi

git -C upstream/tcpdump fetch --tags --force origin >/dev/null 2>&1

if ! git -C upstream/tcpdump rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "ERROR: upstream tcpdump tag does not exist in submodule: $tag" >&2
  exit 1
fi

expected_commit="$(git -C upstream/tcpdump rev-list -n 1 "$tag^{commit}")"
actual_commit="$(git -C upstream/tcpdump rev-parse HEAD)"

if [[ "$expected_commit" != "$actual_commit" ]]; then
  echo "ERROR: upstream/tcpdump is not pinned to $tag" >&2
  echo "expected: $expected_commit" >&2
  echo "actual:   $actual_commit" >&2
  exit 1
fi

echo "Release tag validated: $tag -> $actual_commit"
