# QueryPod

QueryPod is a Flutter-based SQL client/workbench with support for MySQL, PostgreSQL, and SQLite. The current repo includes the desktop/mobile app code, a repeatable local database test lab, and repository-level database integration tests.

## What Is In This Repo

- `lib/`: application code
- `docker-compose.yml`: local MySQL/PostgreSQL services for database testing
- `dev-db/`: Docker-based database lab, seed SQL, and helper scripts
- `integration_test/`: repository/data-source integration tests against real databases

## Quick Start

Start or reset the local database lab:

```bash
./dev-db/scripts/db_reset
```

If `3306` or `5432` is already taken on your machine, create `.env` from `.env.example` and change the exposed ports before starting the lab.

Launch the Linux app against a seeded Docker database or sample preset:

```bash
make run-app PLATFORM=linux TARGET=mysql
```

Run the repository integration tests after exporting DB config or passing `--dart-define` values:

```bash
flutter test integration_test
```

The integration tests fail loudly if the required MySQL/PostgreSQL connection values are missing.

## Local Database Lab

The local DB lab uses Docker Compose to start:

- MySQL 8.0
- PostgreSQL 16

It seeds a deterministic `querypod_lab` database for repository-level testing and can optionally load trusted sample databases for broader manual checks.

Use `dev-db/README.md` as the operational guide for:

- credentials and ports
- local `.env` port overrides for Docker and app launch helpers
- helper scripts such as `db_up`, `db_down`, and `db_reset`
- Linux app launch presets such as `make run-app PLATFORM=linux TARGET=mysql` and `make run-app PLATFORM=linux TARGET=dvdrental`
- optional sample database downloads
- manual verification commands
- exact integration-test invocation examples

See [dev-db/README.md](/home/faizan/Projects/querypod/querypod/dev-db/README.md).

## Repository Integration Tests

The database integration tests are intentionally limited to the repository/data-source layer. They exercise:

- driver connection checks
- `ConnectionMetadataRepositoryImpl`
- `TableDataRepositoryImpl`

Current coverage includes:

- successful and failed connections
- database/schema listing
- table and column discovery
- primary-key and foreign-key detection
- simple `SELECT` queries
- invalid SQL error shaping
- paginated reads against seeded large tables

These tests do not cover UI flows or app screens yet.

## Current Scope

- Local DB lab for MySQL and PostgreSQL is implemented.
- Linux app launch helpers for Docker-backed local/sample databases are implemented.
- Repository-level database integration tests are implemented.
- UI integration tests are not part of the current setup.
- CI wiring for this workflow is not documented here yet.
