# License notes

StaLiBs build scripts and repository metadata are distributed under the MIT license; see `LICENSE`.

The generated StaLiBs bundles contain software from upstream projects with their own licenses:

- tcpdump: see `upstream/tcpdump/LICENSE`
- libpcap: see `upstream/libpcap/LICENSE`
- strace: see `upstream/strace/COPYING` and `upstream/strace/LGPL-2.1-or-later`
- gdb/binutils-gdb: see `upstream/gdb/COPYING`, `upstream/gdb/COPYING.LIB`, `upstream/gdb/COPYING3`, `upstream/gdb/COPYING3.LIB`, `upstream/gdb/gdb/COPYING`, and `upstream/gdb/readline/readline/COPYING`
- nmap: see `upstream/nmap/LICENSE` and bundled dependency license files under `upstream/nmap/*`
- jq: see `upstream/jq/COPYING` and the vendored Oniguruma license at `upstream/jq/vendor/oniguruma/COPYING`
- curl: see `upstream/curl/COPYING` and the license notices under `upstream/curl/LICENSES/`
- OpenSSL: see `upstream/openssl/LICENSE.txt`
- socat: see `upstream/socat/COPYING` and `upstream/socat/COPYING.OpenSSL`
- dig/BIND 9: see `upstream/bind9/COPYING` and `upstream/bind9/LICENSE`
- LMDB (statically linked into dig): see `upstream/lmdb/LICENSE`
- mtr: see `upstream/mtr/COPYING` and `upstream/mtr/BSDCOPYING`
- lsof: see `upstream/lsof/COPYING`
- iproute2: see `upstream/iproute2/COPYING`
- tshark/Wireshark: see `upstream/wireshark/COPYING`
- ripgrep: see `upstream/ripgrep/COPYING`, `upstream/ripgrep/LICENSE-MIT`, and `upstream/ripgrep/UNLICENSE`

Release zip bundles include copies of the relevant upstream license files under `licenses/`.
