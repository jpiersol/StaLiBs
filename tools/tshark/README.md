# tshark

StaLiBs builds `tshark` from the pinned Wireshark submodule in:

- `upstream/wireshark`

The release zip for each platform contains the statically linked executable as `bin/tshark`.

Current build notes:

- built from the official Wireshark `v4.7.1` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- built for offline packet analysis, without plugins, live capture, or optional external protocol libraries.

See the [official Wireshark documentation](https://www.wireshark.org/docs/).
