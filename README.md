# StaLiBs

**Sta**tically **Li**nked **B**inarie**s** built from visible upstream source with GitHub Actions provenance.

The supported tools are `bridge`, `curl`, `dig`, `gdb`, `gdbserver`, `ip`, `jq`, `lsof`, `mtr`, `nmap`, `openssl`, `rg`, `socat`, `ss`, `strace`, `tc`, `tcpdump`, and `tshark`.

## Goals

- Produce portable Linux binaries that do not depend on host shared libraries.
- Target Linux kernel 4.4 and newer.
- Build x86_64, ARM, RISC-V, PowerPC, and IBM Z Linux artifacts from pinned upstream source submodules.
- Publish separate zip bundles per target platform.
- Attach GitHub artifact attestations so consumers can verify that each platform bundle was built by this repository's CI for a given tag.

## Current artifact contents

Release bundles use one stable asset name per platform:

```text
stalibs-linux-x86_64.zip
stalibs-linux-aarch64.zip
stalibs-linux-armv7.zip
stalibs-linux-riscv64.zip
stalibs-linux-ppc64le.zip
stalibs-linux-s390x.zip
```

Each bundle extracts into a top-level directory named after the archive without `.zip`. That directory contains the executables for that platform, using the original upstream binary names, plus Nmap runtime data and the `jq` JSON processor:

```text
stalibs-linux-<arch>/
├── bin/bridge
├── bin/curl
├── bin/dig
├── bin/gdb
├── bin/gdbserver
├── bin/ip
├── bin/jq
├── bin/lsof
├── bin/mtr
├── bin/nmap
├── bin/openssl
├── bin/rg
├── bin/socat
├── bin/ss
├── bin/strace
├── bin/tc
├── bin/tcpdump
├── bin/tshark
├── share/nmap/*
├── metadata/*.buildinfo.txt
├── licenses/*
├── install.sh
├── SHA256SUMS
└── README.txt
```

Architecture targets:

| Bundle | Platform |
| --- | --- |
| `stalibs-*-linux-x86_64.zip` | 64-bit x86 Linux |
| `stalibs-*-linux-aarch64.zip` | 64-bit ARM Linux |
| `stalibs-*-linux-armv7.zip` | 32-bit ARMv7 hard-float Linux |
| `stalibs-*-linux-riscv64.zip` | 64-bit RISC-V Linux |
| `stalibs-*-linux-ppc64le.zip` | 64-bit little-endian PowerPC Linux |
| `stalibs-*-linux-s390x.zip` | IBM Z s390x Linux |

## Upstream source

Upstream projects are checked in as Git submodules:

- `upstream/tcpdump`: <https://github.com/the-tcpdump-group/tcpdump>
- `upstream/libpcap`: <https://github.com/the-tcpdump-group/libpcap>
- `upstream/strace`: <https://github.com/strace/strace>
- `upstream/gdb`: <https://github.com/gnutools/binutils-gdb.git>
- `upstream/nmap`: <https://github.com/nmap/nmap.git>
- `upstream/jq`: <https://github.com/jqlang/jq.git>
- `upstream/curl`: <https://github.com/curl/curl.git>
- `upstream/openssl`: <https://github.com/openssl/openssl.git>
- `upstream/socat`: <https://third-party-mirror.googlesource.com/socat/> (use the `upstream/master` branch; the mirror's `main` branch is stale)
- `upstream/bind9`: <https://github.com/isc-projects/bind9.git>
- `upstream/lmdb`: <https://github.com/LMDB/lmdb.git> (static BIND dependency)
- `upstream/mtr`: <https://github.com/traviscross/mtr.git>
- `upstream/lsof`: <https://github.com/lsof-org/lsof.git>
- `upstream/iproute2`: <https://github.com/iproute2/iproute2.git>
- `upstream/wireshark`: <https://github.com/wireshark/wireshark.git>
- `upstream/ripgrep`: <https://github.com/BurntSushi/ripgrep.git>

StaLiBs releases are produced from the pinned submodule commits in the repository at the pushed Git tag. Release tags do not need to match any upstream project tag.

## Build approach

CI builds in Alpine Linux containers for each target architecture. It uses native GitHub-hosted runners where available and target-native userspaces for compatibility with Autoconf feature checks and Alpine's target static dependency packages. Alpine/musl is used because static musl-linked binaries are significantly more portable than static glibc-linked binaries.

| Target | GitHub runner | Container platform | Notes |
| --- | --- | --- | --- |
| `x86_64` | `ubuntu-24.04` | `linux/amd64` | native |
| `aarch64` | `ubuntu-24.04-arm` | `linux/arm64/v8` | native ARM64 runner, no QEMU |
| `armv7` | `ubuntu-24.04` | `linux/arm/v7` | ARMv7 Alpine under QEMU; slower than cross-compilation but more target-compatible |
| `riscv64` | `ubuntu-24.04` | `linux/riscv64` | RISC-V Alpine under QEMU |
| `ppc64le` | `ubuntu-24.04` | `linux/ppc64le` | little-endian PowerPC Alpine under QEMU |
| `s390x` | `ubuntu-24.04` | `linux/s390x` | IBM Z Alpine under QEMU |

Build preferences:

- `-O3 -pipe` for runtime performance.
- Static link verification with `file` and `readelf`.
- curl is built statically with OpenSSL, while optional protocol and compression libraries are disabled for portability.
- `dig` is built statically from BIND 9 with optional server, resolver, and documentation features disabled.
- gdb and gdbserver are built statically without Python, Guile, debuginfod, Intel PT, Babeltrace, or the GDB compile subsystem to keep the binaries self-contained. LZMA, Zstd, and xxHash support are enabled when Alpine static packages are available.
- iproute2 supplies statically linked `bridge`, `ip`, `ss`, and `tc` commands without dynamically loaded plugins.
- jq is built statically with its vendored Oniguruma regular-expression library.
- lsof is built statically for Linux from the upstream portable source.
- mtr is built statically with its terminal interface and without GTK or JSON output.
- nmap is built statically with bundled libpcap, libdnet, liblinear, liblua, and libpcre, plus Alpine's static OpenSSL and zlib libraries. Ncat, Ndiff, Nping, Zenmap, and libssh2 are not bundled by default. Nmap runtime data is included under `share/nmap`.
- OpenSSL is built as a statically linked `openssl` command with shared libraries, tests, and runtime modules disabled.
- ripgrep (`rg`) is built as a statically linked Rust binary.
- socat is built statically with OpenSSL support and without readline or libwrap.
- strace is built statically with `--enable-mpers=check`, so multiple-personality decoding is enabled when the target build environment can support it.
- `tcpdump` is built with local static `libpcap` and best-effort full feature coverage:
  - libpcap remote capture is enabled.
  - Linux USB, Bluetooth, D-Bus, RDMA, libnl, OpenSSL, libcap-ng, and libsmi support are attempted when static Alpine packages are available.
  - Vendor/proprietary capture SDKs such as DAG, DPDK, Septel, SNF, and TurboCap are not bundled by default.
- tshark is built statically from Wireshark as an offline packet-analysis tool with plugins, capture, and optional external protocol libraries disabled.

## Verifying a release

Download the zip for your platform from the GitHub Release, then verify the GitHub artifact attestation:

```sh
gh attestation verify ./stalibs-linux-x86_64.zip --repo jpiersol/StaLiBs
```

Then verify the internal checksums:

```sh
unzip stalibs-linux-x86_64.zip
cd stalibs-linux-x86_64
sha256sum -c SHA256SUMS
```

## Installing and using the tools

Extract the archive, then run its installer:

```sh
unzip stalibs-linux-x86_64.zip
cd stalibs-linux-x86_64
sudo ./install.sh # installs binaries in /usr/local/bin
```

Without `sudo`, the installer uses `~/.local/bin` and installs Nmap data in `~/.local/share/nmap`. Ensure `~/.local/bin` is on your `PATH`; the installer prints the required `PATH` setting when it is not.

```sh
bridge -V
curl --version
dig -v
gdb --version
gdbserver --version
ip -Version
jq --version
lsof -v
mtr --version
nmap --version
openssl version
rg --version
socat -V
ss -V
strace -V
tc -V
tcpdump -i any
tshark --version
```

Packet capture and some Nmap scan modes generally require root or Linux capabilities:

```sh
sudo setcap cap_net_raw,cap_net_admin=eip "$(command -v tcpdump)" "$(command -v nmap)"
```

## Local build

Docker is required for the same build path used by CI.

```sh
git submodule update --init --recursive
make build ARCH=x86_64
make package ARCH=x86_64 VERSION=v2026.07.0

make build ARCH=aarch64
make package ARCH=aarch64 VERSION=v2026.07.0

make build ARCH=armv7
make package ARCH=armv7 VERSION=v2026.07.0
```

The resulting binaries are written to `dist/bin/` as architecture-qualified working files, for example `bridge-linux-x86_64`, `curl-linux-x86_64`, `dig-linux-x86_64`, `gdb-linux-x86_64`, `gdbserver-linux-x86_64`, `ip-linux-x86_64`, `jq-linux-x86_64`, `lsof-linux-x86_64`, `mtr-linux-x86_64`, `nmap-linux-x86_64`, `openssl-linux-x86_64`, `rg-linux-x86_64`, `socat-linux-x86_64`, `ss-linux-x86_64`, `strace-linux-x86_64`, `tc-linux-x86_64`, `tcpdump-linux-x86_64`, and `tshark-linux-x86_64`. Nmap runtime data is written to `dist/share/nmap/`. Platform zips are written to `dist/` and contain original binary names under `bin/`.

## Releasing

1. The weekly upstream-update workflow commits new upstream pins directly to `main`, or you can manually pin submodules to the desired upstream commits or tags.
2. `.github/workflows/monthly-release.yml` creates and pushes the next sequential release tag (`v2`, then `v3`, and so on) at 04:17 UTC on the 25th of each month. It can also be run manually.
3. The tagged build workflow publishes one zip asset per target platform to the matching GitHub Release and creates GitHub artifact attestations for those zips.

## Upstream release detection

`.github/workflows/upstream-releases.yml` runs early Wednesday mornings and can also be run manually. It checks for new stable upstream release tags and the latest Nmap `master` commit, updates the submodules, and commits changed upstream pins directly to `main`.
