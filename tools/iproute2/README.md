# iproute2

StaLiBs builds selected commands from the pinned iproute2 submodule in:

- `upstream/iproute2`

Each release zip contains these statically linked executables:

- `bin/ip`
- `bin/ss`
- `bin/bridge`
- `bin/tc`

Current build notes:

- built from the official `v7.1.0` release tag;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- built without dynamically loaded plugins.
