# ripgrep

StaLiBs builds ripgrep from the pinned submodule in:

- `upstream/ripgrep`

The release zip for each platform contains the statically linked executable as `bin/rg`.

Current build notes:

- built from the official `15.1.0` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`.

See the [official ripgrep documentation](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md).
