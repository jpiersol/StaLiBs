# gdb

StaLiBs builds GDB from the pinned binutils-gdb submodule in:

- `upstream/gdb`

The release zip for each platform contains the executable as `bin/gdb`.

Current build notes:

- statically linked against musl;
- optimized with `-O3 -pipe`;
- built without Python, Guile, debuginfod, Intel PT, Babeltrace, and the GDB compile subsystem to keep the binary self-contained;
- uses system static GMP, MPFR, Expat, Readline, ncurses, and zlib from the target Alpine userspace;
- LZMA, Zstd, and xxHash support are enabled when Alpine static packages are available.
