# jq

StaLiBs builds `jq` from the pinned submodule in:

- `upstream/jq`

The release zip for each platform contains the statically linked executable as `bin/jq`.

Current build notes:

- built from the official `jq-1.8.2` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- built with jq's vendored Oniguruma regular-expression library.

`jq` is a command-line JSON processor. See the [official documentation](https://jqlang.org/docs/).
