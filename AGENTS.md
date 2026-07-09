# AGENTS.md

Guidance for coding agents working in this repository.

## Project summary

StaLiBs (**Sta**tically **Li**nked **B**inarie**s**) builds portable, statically linked Linux binaries from pinned upstream source submodules with GitHub Actions provenance.

Current tools:

- `tcpdump`, built with local static `libpcap`
- `strace`
- `gdb`
- `nmap`
- `jq`
- `curl`
- `openssl`
- `socat`
- `dig`

Supported targets:

- `x86_64`
- `aarch64`
- `armv7` hard-float

The portability target is Linux kernel 4.4 and newer. Builds use Alpine/musl for static linking.

## Repository layout

- `.github/workflows/build.yml` - CI build, package, attestation, and release flow
- `.github/workflows/upstream-releases.yml` - scheduled upstream tag detection and PR creation
- `scripts/build-tcpdump-alpine.sh` - target-native tcpdump/libpcap build inside Alpine
- `scripts/build-strace-alpine.sh` - target-native strace build inside Alpine
- `scripts/build-gdb-alpine.sh` - target-native gdb build inside Alpine
- `scripts/build-nmap-alpine.sh` - target-native nmap build inside Alpine
- `scripts/build-jq-alpine.sh` - target-native jq build inside Alpine
- `scripts/build-curl-alpine.sh` - target-native curl build inside Alpine
- `scripts/build-openssl-alpine.sh` - target-native OpenSSL build inside Alpine
- `scripts/build-socat-alpine.sh` - target-native socat build inside Alpine
- `scripts/build-dig-alpine.sh` - target-native dig build inside Alpine
- `scripts/ci-build-in-docker.sh` - Docker wrapper used locally and by CI
- `scripts/package-platform.sh` - creates one platform zip containing original binary names
- `scripts/verify-static.sh` - validates ELF binaries are static
- `upstream/tcpdump` - tcpdump submodule
- `upstream/libpcap` - libpcap submodule
- `upstream/strace` - strace submodule
- `upstream/gdb` - binutils-gdb submodule used to build gdb
- `upstream/nmap` - nmap submodule
- `upstream/jq` - jq submodule
- `upstream/curl` - curl submodule
- `upstream/openssl` - OpenSSL submodule
- `upstream/socat` - socat submodule
- `upstream/bind9` - BIND 9 submodule used to build dig
- `tools/*/README.md` - tool-specific notes

## Artifact rules

Release assets must be separate per platform, not one all-platform bundle:

- `stalibs-<version>-linux-x86_64.zip`
- `stalibs-<version>-linux-aarch64.zip`
- `stalibs-<version>-linux-armv7.zip`

Each zip must contain one top-level directory named after the zip without `.zip`. Within that directory, executables must use their original upstream names:

- `bin/tcpdump`
- `bin/strace`
- `bin/gdb`
- `bin/nmap`
- `bin/jq`
- `bin/curl`
- `bin/openssl`
- `bin/socat`
- `bin/dig`

Nmap runtime data should be included at `share/nmap`.

Do not put architecture-qualified executable names inside release zips. Architecture-qualified names such as `tcpdump-linux-x86_64`, `strace-linux-x86_64`, `gdb-linux-x86_64`, and `nmap-linux-x86_64` are acceptable only as intermediate files in `dist/bin/`.

Each zip should also contain:

- `metadata/*.buildinfo.txt`
- `licenses/*`
- `SHA256SUMS`
- `README.txt`
- `install.sh`

## CI/build strategy

Use target-native Alpine userspaces for compatibility with Autoconf checks and target static dependency packages.

- `x86_64`: GitHub runner `ubuntu-24.04`, Docker platform `linux/amd64`, no QEMU
- `aarch64`: GitHub runner `ubuntu-24.04-arm`, Docker platform `linux/arm64/v8`, no QEMU
- `armv7`: GitHub runner `ubuntu-24.04`, Docker platform `linux/arm/v7`, QEMU required

Avoid cross-compilation unless intentionally replacing the target-native strategy and updating the docs accordingly.

## Local commands

Docker is required for local builds.

```sh
git submodule update --init --recursive
make build ARCH=x86_64
make package ARCH=x86_64 VERSION=v2026.07.0
make verify ARCH=x86_64
```

Use the same pattern for `aarch64` and `armv7`.

## Validation before committing

Run syntax checks after shell/YAML changes:

```sh
bash -n scripts/ci-build-in-docker.sh scripts/install-release.sh scripts/update-upstream-tags.sh scripts/write-release-notes.sh scripts/package-platform.sh scripts/build-curl-alpine.sh scripts/build-openssl-alpine.sh scripts/build-socat-alpine.sh scripts/build-dig-alpine.sh
sh -n scripts/build-tcpdump-alpine.sh scripts/build-strace-alpine.sh scripts/build-gdb-alpine.sh scripts/build-nmap-alpine.sh scripts/build-jq-alpine.sh scripts/build-curl-alpine.sh scripts/build-openssl-alpine.sh scripts/build-socat-alpine.sh scripts/build-dig-alpine.sh scripts/verify-static.sh
python3 - <<'PY'
from pathlib import Path
import yaml
for path in Path('.github/workflows').glob('*.yml'):
    yaml.safe_load(path.read_text())
    print(f'YAML OK: {path}')
PY
git diff --check
```

If PyYAML is unavailable, at least inspect workflow syntax carefully.

When CI fails, use GitHub CLI if authenticated:

```sh
gh run list --repo jpiersol/StaLiBs --limit 10
gh run view <run-id> --repo jpiersol/StaLiBs --json status,conclusion,jobs
gh run view <run-id> --repo jpiersol/StaLiBs --log-failed
```

## Release rules

StaLiBs publishes release assets for every pushed Git tag, e.g.:

```sh
git tag -a v2026.07.0 -m "StaLiBs v2026.07.0"
git push origin v2026.07.0
```

Release assets are built from the pinned submodule commits in the repository at that tag.

GitHub artifact attestations are required for published platform zips. Do not remove the attestation step unless replacing it with an equivalent provenance mechanism.

## Upstream submodules

Keep upstream projects pinned to official release tags where practical.

Current submodule purposes:

- `upstream/tcpdump`: tcpdump source
- `upstream/libpcap`: static libpcap for tcpdump
- `upstream/strace`: strace source
- `upstream/gdb`: binutils-gdb source for gdb
- `upstream/nmap`: nmap source; upstream does not publish Git release tags, so automation tracks the pinned master commit
- `upstream/jq`: jq source, pinned to an official release tag
- `upstream/curl`: curl source, pinned to an official release tag
- `upstream/openssl`: OpenSSL source, pinned to an official release tag
- `upstream/socat`: socat source, pinned to an official release tag
- `upstream/bind9`: BIND 9 source, pinned to an official release tag

Use `scripts/update-upstream-tags.sh` or the scheduled workflow to update upstream pins.

## Coding style

- Shell scripts should use `set -euo pipefail` for Bash scripts and `set -eu` for POSIX `sh` scripts.
- Alpine container scripts should avoid Bash unless `bash` is explicitly installed.
- Prefer small, focused scripts over embedding complex logic directly in workflow YAML.
- Keep README and release notes aligned with artifact names and zip contents.

## Security/provenance expectations

- Do not commit generated binaries, build directories, or zip artifacts.
- Do not commit credentials or GitHub tokens.
- Do not broaden GitHub Actions permissions unless required.
- Preserve static-link checks with `scripts/verify-static.sh`.
- Prefer transparent CI-built artifacts over local/manual release uploads.
