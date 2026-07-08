ARCH ?= x86_64
VERSION ?= $(shell git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || git -C upstream/tcpdump describe --tags --always 2>/dev/null || echo tcpdump-local)

.PHONY: build package verify clean update-upstream

build:
	./scripts/ci-build-in-docker.sh $(ARCH)

package:
	./scripts/package-tcpdump-platform.sh $(ARCH) $(VERSION) dist dist

verify:
	./scripts/verify-static.sh dist/bin/tcpdump-linux-$(ARCH)

update-upstream:
	./scripts/update-upstream-tags.sh

clean:
	rm -rf .build dist
