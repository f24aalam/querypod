.PHONY: linux-deb linux-package
.PHONY: db-up db-down db-reset db-fetch-samples db-prepare-samples db-load-samples db-reset-samples

linux-deb:
	./scripts/build-linux-deb.sh

linux-package: linux-deb

db-up:
	./dev-db/scripts/db_up

db-down:
	./dev-db/scripts/db_down

db-reset:
	./dev-db/scripts/db_reset

db-fetch-samples:
	./dev-db/scripts/fetch_samples

db-prepare-samples:
	./dev-db/scripts/prepare_samples

db-load-samples:
	./dev-db/scripts/load_samples

db-reset-samples:
	./dev-db/scripts/reset_samples
