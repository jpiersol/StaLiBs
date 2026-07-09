ARCH ?= x86_64
VERSION ?= $(shell git -C upstream/tcpdump describe --tags --exact-match 2>/dev/null || git -C upstream/tcpdump describe --tags --always 2>/dev/null || echo tcpdump-local)

.PHONY: build build-tcpdump build-strace build-gdb build-nmap build-jq build-curl build-openssl build-socat build-dig build-mtr build-lsof package verify clean update-upstream

build: build-tcpdump build-strace build-gdb build-nmap build-jq build-curl build-openssl build-socat build-dig build-mtr build-lsof

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

build-openssl:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-openssl-alpine.sh

build-socat:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-socat-alpine.sh

build-dig:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-dig-alpine.sh

build-mtr:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-mtr-alpine.sh

build-lsof:
	./scripts/ci-build-in-docker.sh $(ARCH) scripts/build-lsof-alpine.sh

package:
	./scripts/package-platform.sh $(ARCH) $(VERSION) dist dist

verify:
	./scripts/verify-static.sh dist/bin/tcpdump-linux-$(ARCH) dist/bin/strace-linux-$(ARCH) dist/bin/gdb-linux-$(ARCH) dist/bin/nmap-linux-$(ARCH) dist/bin/jq-linux-$(ARCH) dist/bin/curl-linux-$(ARCH) dist/bin/openssl-linux-$(ARCH) dist/bin/socat-linux-$(ARCH) dist/bin/dig-linux-$(ARCH) dist/bin/mtr-linux-$(ARCH) dist/bin/lsof-linux-$(ARCH)

update-upstream:
	./scripts/update-upstream-tags.sh

clean:
	rm -rf .build dist
