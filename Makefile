.PHONY: linux-deb linux-package

linux-deb:
	./scripts/build-linux-deb.sh

linux-package: linux-deb
