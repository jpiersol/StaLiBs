ARCH ?= x86_64
VERSION ?= $(shell git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || git -C upstream/tcpdump describe --tags --always 2>/dev/null || echo tcpdump-local)

.PHONY: build build-tcpdump build-strace build-gdb build-nmap build-jq build-curl package verify clean update-upstream

build: build-tcpdump build-strace build-gdb build-nmap build-jq build-curl

build-tcpdump:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-tcpdump-alpine.sh

build-strace:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-strace-alpine.sh

build-gdb:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-gdb-alpine.sh

build-nmap:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-nmap-alpine.sh

build-jq:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-jq-alpine.sh

build-curl:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-curl-alpine.sh

package:
	./scripts/package-platform.sh $(ARCH) $(VERSION) dist dist

verify:
	./scripts/verify-static.sh dist/bin/tcpdump-linux-$(ARCH) dist/bin/strace-linux-$(ARCH) dist/bin/gdb-linux-$(ARCH) dist/bin/nmap-linux-$(ARCH) dist/bin/jq-linux-$(ARCH) dist/bin/curl-linux-$(ARCH)

update-upstream:
	./scripts/update-upstream-tags.sh

clean:
	rm -rf .build dist
