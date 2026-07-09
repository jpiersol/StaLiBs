# nmap

StaLiBs builds Nmap from the pinned submodule in:

- `upstream/nmap`

The release zip for each platform contains the executable as `bin/nmap` and Nmap's runtime data files under `share/nmap`.

Current build notes:

- statically linked against musl;
- optimized with `-O3 -pipe`;
- built with bundled libpcap, libdnet, liblinear, liblua, and libpcre;
- built with Alpine's static OpenSSL and zlib libraries;
- built without Ncat, Ndiff, Nping, Zenmap, or libssh2.

Nmap looks for runtime data in `../share/nmap` relative to `bin/nmap`, so the release zip layout works without setting `NMAPDIR`.
