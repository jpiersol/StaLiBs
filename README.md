# StaLiBs

**Sta**tically **Li**nked **B**inarie**s** built from visible upstream source with GitHub Actions provenance.

The supported tools are `tcpdump`, `strace`, `gdb`, `nmap`, `jq`, `curl`, `openssl`, `socat`, `dig`, `mtr`, `lsof`, `tshark`, `rg`, and the `iproute2` commands `ip`, `ss`, `bridge`, and `tc`.

## Goals

- Produce portable Linux binaries that do not depend on host shared libraries.
- Target Linux kernel 4.4 and newer.
- Build x86_64 and ARM Linux artifacts from pinned upstream source submodules.
- Publish separate zip bundles per target platform.
- Attach GitHub artifact attestations so consumers can verify that each platform bundle was built by this repository's CI for a given tag.

## Current artifact contents

Release bundles are named from the Git tag that produced them (`/` and spaces are written as `-` in filenames):

```text
stalibs-<tag>-linux-x86_64.zip
stalibs-<tag>-linux-aarch64.zip
stalibs-<tag>-linux-armv7.zip
```

Each bundle extracts into a top-level directory named after the archive without `.zip`. That directory contains the executables for that platform, using the original upstream binary names, plus Nmap runtime data and the `jq` JSON processor:

```text
stalibs-<tag>-linux-<arch>/
├── bin/tcpdump
├── bin/strace
├── bin/gdb
├── bin/nmap
├── bin/jq
├── bin/curl
├── bin/openssl
├── bin/socat
├── bin/dig
├── bin/mtr
├── bin/lsof
├── bin/ip
├── bin/ss
├── bin/bridge
├── bin/tc
├── bin/tshark
├── bin/rg
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
- `upstream/socat`: <https://repo.or.cz/socat.git>
- `upstream/bind9`: <https://github.com/isc-projects/bind9.git>
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

Build preferences:

- `-O3 -pipe` for runtime performance.
- Static link verification with `file` and `readelf`.
- Best-effort full tcpdump/libpcap feature coverage:
  - libpcap remote capture is enabled.
  - Linux USB, Bluetooth, D-Bus, RDMA, libnl, OpenSSL, libcap-ng, and libsmi support are attempted when static Alpine packages are available.
  - Vendor/proprietary capture SDKs such as DAG, DPDK, Septel, SNF, and TurboCap are not bundled by default.
- strace is built statically with `--enable-mpers=check`, so multiple-personality decoding is enabled when the target build environment can support it.
- gdb is built statically without Python, Guile, debuginfod, Intel PT, Babeltrace, or the GDB compile subsystem to keep the binary self-contained. LZMA, Zstd, and xxHash support are enabled when Alpine static packages are available.
- nmap is built statically with bundled libpcap, libdnet, liblinear, liblua, and libpcre, plus Alpine's static OpenSSL and zlib libraries. Ncat, Ndiff, Nping, Zenmap, and libssh2 are not bundled by default. Nmap runtime data is included under `share/nmap`.
- jq is built statically with its vendored Oniguruma regular-expression library.
- curl is built statically with OpenSSL, while optional protocol and compression libraries are disabled for portability.
- OpenSSL is built as a statically linked `openssl` command with shared libraries, tests, and runtime modules disabled.
- socat is built statically with OpenSSL support and without readline or libwrap.
- `dig` is built statically from BIND 9 with optional server, resolver, and documentation features disabled.
- mtr is built statically with its terminal interface and without GTK or JSON output.
- lsof is built statically for Linux from the upstream portable source.
- iproute2 supplies statically linked `ip`, `ss`, `bridge`, and `tc` commands without dynamically loaded plugins.
- tshark is built statically from Wireshark as an offline packet-analysis tool with plugins, capture, and optional external protocol libraries disabled.
- ripgrep (`rg`) is built as a statically linked Rust binary.

## Verifying a release

Download the zip for your platform from the GitHub Release, then verify the GitHub artifact attestation:

```sh
gh attestation verify ./stalibs-v2026.07.0-linux-x86_64.zip --repo jpiersol/StaLiBs
```

Then verify the internal checksums:

```sh
unzip stalibs-v2026.07.0-linux-x86_64.zip
cd stalibs-v2026.07.0-linux-x86_64
sha256sum -c SHA256SUMS
```

## Installing and using the tools

Extract the archive, then run its installer:

```sh
unzip stalibs-v2026.07.0-linux-x86_64.zip
cd stalibs-v2026.07.0-linux-x86_64
sudo ./install.sh # installs binaries in /usr/local/bin
```

Without `sudo`, the installer uses `~/.local/bin` and installs Nmap data in `~/.local/share/nmap`. Ensure `~/.local/bin` is on your `PATH`; the installer prints the required `PATH` setting when it is not.

```sh
tcpdump -i any
strace -V
gdb --version
nmap --version
jq --version
curl --version
openssl version
socat -V
dig -v
mtr --version
lsof -v
ip -Version
ss -V
bridge -V
tc -V
tshark --version
rg --version
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

The resulting binaries are written to `dist/bin/` as architecture-qualified working files, for example `tcpdump-linux-x86_64`, `strace-linux-x86_64`, `gdb-linux-x86_64`, `nmap-linux-x86_64`, `jq-linux-x86_64`, `curl-linux-x86_64`, `openssl-linux-x86_64`, `socat-linux-x86_64`, `dig-linux-x86_64`, `mtr-linux-x86_64`, `lsof-linux-x86_64`, `ip-linux-x86_64`, `ss-linux-x86_64`, `bridge-linux-x86_64`, `tc-linux-x86_64`, `tshark-linux-x86_64`, and `rg-linux-x86_64`. Nmap runtime data is written to `dist/share/nmap/`. Platform zips are written to `dist/` and contain original binary names under `bin/`.

## Releasing

1. Merge an upstream-update PR, or manually pin submodules to the desired upstream commits or tags.
2. Create and push any StaLiBs release tag:

   ```sh
   git tag -a v2026.07.0 -m "StaLiBs v2026.07.0"
   git push origin v2026.07.0
   ```

3. The build workflow runs for every pushed tag, publishes one zip asset per target platform to the matching GitHub Release, and creates GitHub artifact attestations for those zips.

## Upstream release detection

`.github/workflows/upstream-releases.yml` runs daily and can also be run manually. It checks for new stable upstream release tags and the latest Nmap `master` commit, updates the submodules, and opens or updates a PR.
