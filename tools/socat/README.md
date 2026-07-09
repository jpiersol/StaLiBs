# socat

StaLiBs builds `socat` from the pinned submodule in:

- `upstream/socat`

The release zip for each platform contains the statically linked executable as `bin/socat`.

Current build notes:

- built from the official socat `tag-1.8.1.3` release;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- built with OpenSSL support and without readline or libwrap.

See the upstream [socat documentation](http://www.dest-unreach.org/socat/).
