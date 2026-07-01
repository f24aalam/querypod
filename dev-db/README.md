# QueryPod Dev DB Test Lab

This lab provides a repeatable local database environment for QueryPod. It starts MySQL 8.0 and PostgreSQL 16, seeds a small QueryPod-owned fixture database named `querypod_lab`, can optionally download and load trusted third-party sample databases for broader manual testing, and now supports repository-level Flutter/Dart integration tests against the seeded databases.

The integration tests are focused on repository and data-source behavior only. They do not touch screens or UI widgets.

## Prerequisites

- Docker Desktop or Docker Engine with the Compose plugin
- `bash`
- `curl` for sample downloads
- `tar`
- `unzip` for `dvdrental.zip`

## Layout

- `docker-compose.yml`: MySQL and PostgreSQL services
- `dev-db/mysql/init/`: MySQL init SQL for `querypod_lab`
- `dev-db/postgres/init/`: PostgreSQL init SQL for `querypod_lab`
- `dev-db/scripts/`: lifecycle and sample-dataset helpers
- `dev-db/downloads/`: ignored cache of downloaded archives
- `dev-db/prepared/`: ignored extracted artifacts ready to import

## Local credentials

- MySQL
  - host: `127.0.0.1`
  - port: `3306`
  - user: `querypod`
  - password: `querypod`
  - root password: `rootpass`
  - seeded database: `querypod_lab`
- PostgreSQL
  - host: `127.0.0.1`
  - port: `5432`
  - user: `querypod`
  - password: `querypod`
  - seeded database: `querypod_lab`

## Core commands

From `querypod/`:

```bash
./dev-db/scripts/db_up
./dev-db/scripts/db_down
./dev-db/scripts/db_reset
```

Target a single engine when needed:

```bash
./dev-db/scripts/db_up mysql
./dev-db/scripts/db_reset postgres
```

Behavior:

- `db_up`: starts the requested services and waits for healthy status
- `db_down`: stops the requested services; when run without a target it performs `docker compose down`
- `db_reset`: recreates the requested service volumes and re-runs the init SQL

## Seeded `querypod_lab` coverage

The built-in SQL fixtures intentionally cover:

- normal relational tables for basic browsing
- reserved keyword identifiers
- JSON and `jsonb`
- nullable and edge-case date/time values
- self-referential and many-to-many relations
- secondary indexes and a view
- a `large_events` table with 1,000 rows for paging/count testing

## Optional sample databases

Trusted sample sources used by the helper scripts:

- MySQL Sakila: `https://downloads.mysql.com/docs/sakila-db.tar.gz`
- MySQL World: `https://downloads.mysql.com/docs/world-db.tar.gz`
- MySQL Employees: `https://github.com/datacharmer/test_db/archive/refs/heads/master.tar.gz`
- PostgreSQL DVD Rental: `https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip`

Helper commands:

```bash
./dev-db/scripts/fetch_samples
./dev-db/scripts/prepare_samples
./dev-db/scripts/load_samples
./dev-db/scripts/reset_samples
```

Each command also accepts one of:

- `mysql`
- `postgres`
- `sakila`
- `world`
- `employees`
- `dvdrental`

Examples:

```bash
./dev-db/scripts/load_samples mysql
./dev-db/scripts/load_samples dvdrental
./dev-db/scripts/reset_samples employees
```

Loaded sample database names:

- MySQL: `sakila`, `world`, `employees`
- PostgreSQL: `dvdrental`

The third-party datasets are not loaded during `db_up`. That keeps the default startup fast and keeps the core QueryPod fixtures deterministic.

## Manual verification

Quick smoke checks after `db_reset`:

```bash
docker compose ps
docker exec -it querypod-mysql80 mysql -uquerypod -pquerypod -D querypod_lab -e "SHOW TABLES;"
docker exec -it querypod-postgres16 psql -U querypod -d querypod_lab -c "\dt"
```

After loading optional samples:

```bash
docker exec -it querypod-mysql80 mysql -uquerypod -pquerypod -e "SHOW DATABASES;"
docker exec -it querypod-postgres16 psql -U querypod -d postgres -c "\l"
```

## Repository integration tests

These tests live under `integration_test/` and exercise only:

- driver connection checks
- `ConnectionMetadataRepositoryImpl`
- `TableDataRepositoryImpl`

They verify:

- successful and failed connections
- database/schema listing
- table and column discovery
- primary-key and foreign-key detection
- simple `SELECT` execution
- invalid SQL error shaping
- paginated row reads against `large_events`

Start the lab first:

```bash
./dev-db/scripts/db_reset
```

Run with environment variables:

```bash
QUERYPOD_MYSQL_HOST=127.0.0.1 \
QUERYPOD_MYSQL_PORT=3306 \
QUERYPOD_MYSQL_USER=querypod \
QUERYPOD_MYSQL_PASSWORD=querypod \
QUERYPOD_MYSQL_DATABASE=querypod_lab \
QUERYPOD_PG_HOST=127.0.0.1 \
QUERYPOD_PG_PORT=5432 \
QUERYPOD_PG_USER=querypod \
QUERYPOD_PG_PASSWORD=querypod \
QUERYPOD_PG_DATABASE=querypod_lab \
flutter test integration_test
```

Run with `--dart-define` values:

```bash
flutter test integration_test \
  --dart-define=QUERYPOD_MYSQL_HOST=127.0.0.1 \
  --dart-define=QUERYPOD_MYSQL_PORT=3306 \
  --dart-define=QUERYPOD_MYSQL_USER=querypod \
  --dart-define=QUERYPOD_MYSQL_PASSWORD=querypod \
  --dart-define=QUERYPOD_MYSQL_DATABASE=querypod_lab \
  --dart-define=QUERYPOD_PG_HOST=127.0.0.1 \
  --dart-define=QUERYPOD_PG_PORT=5432 \
  --dart-define=QUERYPOD_PG_USER=querypod \
  --dart-define=QUERYPOD_PG_PASSWORD=querypod \
  --dart-define=QUERYPOD_PG_DATABASE=querypod_lab
```

The test config reader checks `--dart-define` first and then falls back to environment variables. Missing values fail loudly with a setup message instead of silently skipping.

## Notes

- If port `3306` or `5432` is already in use, stop the conflicting local service or adjust `docker-compose.yml`.
- `dev-db/downloads/` and `dev-db/prepared/` are intentionally ignored by git.
- If an upstream sample URL changes, the download step will fail loudly instead of using an untrusted mirror.
