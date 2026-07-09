# lsof

StaLiBs builds `lsof` from the pinned submodule in:

- `upstream/lsof`

The release zip for each platform contains the statically linked executable as `bin/lsof`.

Current build notes:

- built from the official `4.99.7` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`.

`lsof` lists open files and the processes that hold them.
