ARCH ?= x86_64
VERSION ?= $(shell git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || git -C upstream/tcpdump describe --tags --always 2>/dev/null || echo tcpdump-local)

.PHONY: build build-tcpdump build-strace package verify clean update-upstream

build: build-tcpdump build-strace

build-tcpdump:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-tcpdump-alpine.sh

build-strace:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-strace-alpine.sh

package:
	./scripts/package-platform.sh $(ARCH) $(VERSION) dist dist

verify:
	./scripts/verify-static.sh dist/bin/tcpdump-linux-$(ARCH) dist/bin/strace-linux-$(ARCH)

update-upstream:
	./scripts/update-upstream-tags.sh

clean:
	rm -rf .build dist
