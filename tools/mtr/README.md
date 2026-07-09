# mtr

StaLiBs builds `mtr` from the pinned submodule in:

- `upstream/mtr`

The release zip for each platform contains the statically linked executable as `bin/mtr`.

Current build notes:

- built from the official `v0.96` release tag;
- statically linked against musl and ncurses;
- optimized with `-O3 -pipe`;
- built without GTK or JSON output.

See the [official mtr documentation](https://www.bitwizard.nl/mtr/).
