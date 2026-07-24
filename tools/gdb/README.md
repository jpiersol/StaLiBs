# gdb

StaLiBs builds GDB from the pinned binutils-gdb submodule in:

- `upstream/gdb`

The release zip for each platform contains the executables as `bin/gdb` and `bin/gdbserver`.

Current build notes:

- statically linked against musl;
- optimized with `-O3 -pipe`;
- built without Python, Guile, debuginfod, Intel PT, Babeltrace, and the GDB compile subsystem to keep both binaries self-contained;
- uses system static GMP, MPFR, Expat, Readline, ncurses, and zlib from the target Alpine userspace;
- LZMA, Zstd, and xxHash support are enabled when Alpine static packages are available.
