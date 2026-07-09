# OpenSSL

StaLiBs builds the OpenSSL command-line tool from the pinned submodule in:

- `upstream/openssl`

The release zip for each platform contains the statically linked executable as `bin/openssl`.

Current build notes:

- built from the official `openssl-4.0.1` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- shared libraries, tests, and runtime modules are disabled.

See the [official OpenSSL documentation](https://docs.openssl.org/).
