# StaLiBs

**Sta**tically **Li**nked **B**inarie**s** built from visible upstream source with GitHub Actions provenance.

The first supported tool is `tcpdump`; `strace` is planned next.

## Goals

- Produce portable Linux binaries that do not depend on host shared libraries.
- Target Linux kernel 4.4 and newer.
- Build x86_64 and ARM Linux artifacts from pinned upstream source submodules.
- Publish a single zip bundle per release.
- Attach GitHub artifact attestations so consumers can verify that the bundle was built by this repository's CI for a given tag.

## Current artifact contents

Release bundles are named like:

```text
stalibs-tcpdump-4.99.6.zip
```

The bundle contains:

```text
bin/tcpdump-linux-x86_64
bin/tcpdump-linux-aarch64
bin/tcpdump-linux-armv7
metadata/*.buildinfo.txt
licenses/*
SHA256SUMS
README.txt
```

Architecture targets:

| Artifact | Platform |
| --- | --- |
| `tcpdump-linux-x86_64` | 64-bit x86 Linux |
| `tcpdump-linux-aarch64` | 64-bit ARM Linux |
| `tcpdump-linux-armv7` | 32-bit ARMv7 hard-float Linux |

## Upstream source

Upstream projects are checked in as Git submodules:

- `upstream/tcpdump`: <https://github.com/the-tcpdump-group/tcpdump>
- `upstream/libpcap`: <https://github.com/the-tcpdump-group/libpcap>

StaLiBs release tags for tcpdump intentionally match upstream tcpdump release tags, for example:

```text
tcpdump-4.99.6
```

The release workflow validates that the `upstream/tcpdump` submodule is pinned to the same upstream tcpdump tag before publishing a GitHub Release asset.

## Build approach

CI builds in Alpine Linux containers for each target architecture. It uses native GitHub-hosted runners where available and target-native userspaces for compatibility with Autoconf feature checks and Alpine's target static dependency packages. Alpine/musl is used because static musl-linked binaries are significantly more portable than static glibc-linked binaries.

| Target | GitHub runner | Container platform | Notes |
| --- | --- | --- | --- |
| `x86_64` | `ubuntu-24.04` | `linux/amd64` | native |
| `aarch64` | `ubuntu-24.04-arm` | `linux/arm64/v8` | native ARM64 runner, no QEMU |
| `armv7` | `ubuntu-24.04` | `linux/arm/v7` | ARMv7 Alpine under QEMU; slower than cross-compilation but more target-compatible |

Build preferences:

- `-O3 -pipe` for runtime performance.
- Static link verification with `file` and `readelf`.
- Best-effort full tcpdump/libpcap feature coverage:
  - libpcap remote capture is enabled.
  - Linux USB, Bluetooth, D-Bus, RDMA, libnl, OpenSSL, libcap-ng, and libsmi support are attempted when static Alpine packages are available.
  - Vendor/proprietary capture SDKs such as DAG, DPDK, Septel, SNF, and TurboCap are not bundled by default.

## Verifying a release

Download the zip from the GitHub Release, then verify the GitHub artifact attestation:

```sh
gh attestation verify ./stalibs-tcpdump-4.99.6.zip --repo jpiersol/StaLiBs
```

Then verify the internal checksums:

```sh
unzip stalibs-tcpdump-4.99.6.zip -d stalibs-tcpdump-4.99.6
cd stalibs-tcpdump-4.99.6
sha256sum -c SHA256SUMS
```

## Using tcpdump

```sh
unzip stalibs-tcpdump-4.99.6.zip
chmod +x bin/tcpdump-linux-x86_64
sudo ./bin/tcpdump-linux-x86_64 -i any
```

Packet capture generally requires root or Linux capabilities:

```sh
sudo setcap cap_net_raw,cap_net_admin=eip ./bin/tcpdump-linux-x86_64
```

## Local build

Docker is required for the same build path used by CI.

```sh
git submodule update --init --recursive
make build ARCH=x86_64
make build ARCH=aarch64
make build ARCH=armv7
```

The resulting binaries are written to `dist/bin/`.

## Releasing tcpdump

1. Merge an upstream-update PR, or manually pin submodules to official upstream release tags.
2. Create a StaLiBs tag matching the upstream tcpdump release tag:

   ```sh
   git tag -a tcpdump-4.99.6 -m "StaLiBs tcpdump-4.99.6"
   git push origin tcpdump-4.99.6
   ```

3. The build workflow publishes one zip asset to the matching GitHub Release and creates a GitHub artifact attestation for that zip.

## Upstream release detection

`.github/workflows/upstream-releases.yml` runs daily and can also be run manually. It checks for new stable upstream tcpdump/libpcap release tags, updates the submodules, and opens or updates a PR.
