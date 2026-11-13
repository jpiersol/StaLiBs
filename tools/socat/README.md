# socat

StaLiBs builds `socat` from the pinned submodule in:

- `upstream/socat`, from the [official repository](https://repo.or.cz/socat.git)

The weekly updater selects the latest stable `tag-*` release from this repository.
The third-party Google mirror is not used because it does not retain all release tags and commits.

For an existing checkout, refresh the configured submodule URL before updating:

```sh
git submodule sync -- upstream/socat
git submodule update --init --recursive upstream/socat
```

The release zip for each platform contains the statically linked executable as `bin/socat`.

Current build notes:

- built from the official socat `tag-1.8.1.3` release;
- statically linked against musl;
- optimized with `-O3 -pipe`;
- built with OpenSSL support and without readline or libwrap.

See the upstream [socat documentation](http://www.dest-unreach.org/socat/).
