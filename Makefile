.PHONY: linux-deb linux-package
.PHONY: db-up db-down db-reset db-fetch-samples db-prepare-samples db-load-samples db-reset-samples
.PHONY: run-app app-linux-mysql app-linux-postgres app-linux-sakila app-linux-world app-linux-employees app-linux-dvdrental

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

run-app:
	./dev-db/scripts/run_app --platform "$(PLATFORM)" $(if $(DB),--db "$(DB)") $(if $(EXAMPLE),--example "$(EXAMPLE)") $(if $(PORT),--port "$(PORT)")

app-linux-mysql:
	$(MAKE) run-app PLATFORM=linux DB=mysql

app-linux-postgres:
	$(MAKE) run-app PLATFORM=linux DB=postgres

app-linux-sakila:
	$(MAKE) run-app PLATFORM=linux EXAMPLE=sakila

app-linux-world:
	$(MAKE) run-app PLATFORM=linux EXAMPLE=world

app-linux-employees:
	$(MAKE) run-app PLATFORM=linux EXAMPLE=employees

app-linux-dvdrental:
	$(MAKE) run-app PLATFORM=linux EXAMPLE=dvdrental
