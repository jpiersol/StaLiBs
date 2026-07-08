ARCH ?= x86_64

.PHONY: build verify clean update-upstream

build:
	./scripts/ci-build-in-docker.sh $(ARCH)

verify:
	./scripts/verify-static.sh dist/bin/tcpdump-linux-$(ARCH)

update-upstream:
	./scripts/update-upstream-tags.sh

clean:
	rm -rf .build dist
