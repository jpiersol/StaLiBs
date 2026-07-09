# dig

StaLiBs builds `dig` from the pinned BIND 9 submodule in:

- `upstream/bind9`

The release zip for each platform contains the statically linked executable as `bin/dig`.

Current build notes:

- built from the official BIND 9 `v9.21.23` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- optional BIND server, resolver, and documentation features are disabled.

See the [official BIND documentation](https://bind9.readthedocs.io/).
