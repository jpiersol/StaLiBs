# strace

StaLiBs builds strace from the pinned submodule in:

- `upstream/strace`

The release zip for each platform contains the executable as `bin/strace`.

Current build notes:

- statically linked against musl;
- optimized with `-O3 -pipe`;
- configured with `--enable-mpers=check` so multiple-personality decoding is enabled when the target build environment can support it.
