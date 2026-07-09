# curl

StaLiBs builds `curl` from the pinned submodule in:

- `upstream/curl`

The release zip for each platform contains the statically linked executable as `bin/curl`.

Current build notes:

- built from the official `curl-8_21_0` release tag;
- statically linked against musl and OpenSSL;
- optimized with `-O3 -pipe`;
- optional protocol and compression libraries are disabled for portability.

See the [official curl documentation](https://curl.se/docs/).
