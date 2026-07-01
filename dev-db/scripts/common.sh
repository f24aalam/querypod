#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_DB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${DEV_DB_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
DOWNLOAD_DIR="${DEV_DB_DIR}/downloads"
PREPARED_DIR="${DEV_DB_DIR}/prepared"
ENV_FILE="${PROJECT_ROOT}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "${ENV_FILE}"
  set +a
fi

MYSQL_SERVICE="mysql80"
POSTGRES_SERVICE="postgres16"
MYSQL_CONTAINER="querypod-mysql80"
POSTGRES_CONTAINER="querypod-postgres16"
MYSQL_HOST="${QUERYPOD_MYSQL_HOST:-127.0.0.1}"
POSTGRES_HOST="${QUERYPOD_PG_HOST:-127.0.0.1}"
MYSQL_PORT="${QUERYPOD_MYSQL_PORT:-3306}"
POSTGRES_PORT="${QUERYPOD_PG_PORT:-5432}"

MYSQL_ROOT_PASSWORD="rootpass"
MYSQL_APP_USER="querypod"
MYSQL_APP_PASSWORD="querypod"
MYSQL_APP_DB="querypod_lab"

POSTGRES_APP_USER="querypod"
POSTGRES_APP_PASSWORD="querypod"
POSTGRES_APP_DB="querypod_lab"

SAMPLE_SAKILA_URL="https://downloads.mysql.com/docs/sakila-db.tar.gz"
SAMPLE_WORLD_URL="https://downloads.mysql.com/docs/world-db.tar.gz"
SAMPLE_EMPLOYEES_URL="https://github.com/datacharmer/test_db/archive/refs/heads/master.tar.gz"
SAMPLE_DVDRENTAL_URL="https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip"
SAMPLE_DVDRENTAL_FALLBACK_URL="https://raw.githubusercontent.com/robconery/dvdrental/master/dvdrental.tar"

COMPOSE_CMD=(docker compose -f "${COMPOSE_FILE}")

mkdir -p "${DOWNLOAD_DIR}" "${PREPARED_DIR}"

log() {
  printf '[dev-db] %s\n' "$*"
}

die() {
  printf '[dev-db] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

is_port_in_use() {
  local port="${1}"

  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :${port} )" 2>/dev/null | tail -n +2 | grep -q .
    return $?
  fi

  return 1
}

compose() {
  (cd "${PROJECT_ROOT}" && "${COMPOSE_CMD[@]}" "$@")
}

service_for_target() {
  case "${1:-both}" in
    ""|both) ;;
    mysql) printf '%s\n' "${MYSQL_SERVICE}" ;;
    postgres) printf '%s\n' "${POSTGRES_SERVICE}" ;;
    *) die "Unsupported target '${1}'. Use: mysql, postgres, or omit it." ;;
  esac
}

ensure_target_running() {
  local target="${1}"
  case "${target}" in
    mysql)
      wait_for_service mysql
      ;;
    postgres)
      wait_for_service postgres
      ;;
    *)
      die "Unsupported target '${target}'"
      ;;
  esac
}

wait_for_service() {
  local target="${1}"
  local service

  case "${target}" in
    mysql) service="${MYSQL_SERVICE}" ;;
    postgres) service="${POSTGRES_SERVICE}" ;;
    *) die "Unsupported service '${target}'" ;;
  esac

  log "Waiting for ${service} to become healthy"
  for _ in $(seq 1 60); do
    local state
    state="$(compose ps --format json "${service}" 2>/dev/null | sed -n 's/.*"Health":"\([^"]*\)".*/\1/p' | head -n 1)"
    if [[ "${state}" == "healthy" ]]; then
      log "${service} is healthy"
      return 0
    fi
    sleep 2
  done

  compose ps
  die "${service} did not become healthy in time"
}

mysql_exec() {
  docker exec -i "${MYSQL_CONTAINER}" mysql -uroot "-p${MYSQL_ROOT_PASSWORD}" "$@"
}

postgres_psql() {
  docker exec -i "${POSTGRES_CONTAINER}" psql -v ON_ERROR_STOP=1 -U "${POSTGRES_APP_USER}" "$@"
}

postgres_restore() {
  docker exec -i "${POSTGRES_CONTAINER}" pg_restore -U "${POSTGRES_APP_USER}" "$@"
}

download_if_missing() {
  local url="${1}"
  local output="${2}"

  if [[ -f "${output}" ]]; then
    log "Using cached download $(basename "${output}")"
    return 0
  fi

  require_cmd curl
  log "Downloading $(basename "${output}")"
  curl -fL "${url}" -o "${output}"
}

download_first_available() {
  local output="${1}"
  shift

  if [[ -f "${output}" ]]; then
    log "Using cached download $(basename "${output}")"
    return 0
  fi

  require_cmd curl

  local url
  local errors=()
  for url in "$@"; do
    log "Downloading $(basename "${output}") from ${url}"
    if curl -fL "${url}" -o "${output}"; then
      return 0
    fi

    errors+=("${url}")
    rm -f "${output}"
  done

  die "Failed to download $(basename "${output}") from all configured sources: ${errors[*]}"
}

extract_tarball() {
  local archive="${1}"
  local destination="${2}"

  require_cmd tar
  rm -rf "${destination}"
  mkdir -p "${destination}"
  tar -xzf "${archive}" -C "${destination}"
}

extract_zip() {
  local archive="${1}"
  local destination="${2}"

  require_cmd unzip
  rm -rf "${destination}"
  mkdir -p "${destination}"
  unzip -oq "${archive}" -d "${destination}"
}

normalize_line_endings() {
  local path="${1}"
  if command -v perl >/dev/null 2>&1; then
    perl -pi -e 's/\r\n/\n/g' "${path}"
  fi
}

sample_enabled() {
  local requested="${1:-all}"
  local sample="${2}"

  case "${requested}" in
    all) return 0 ;;
    mysql)
      [[ "${sample}" == "sakila" || "${sample}" == "world" || "${sample}" == "employees" ]]
      ;;
    postgres)
      [[ "${sample}" == "dvdrental" ]]
      ;;
    *)
      [[ "${requested}" == "${sample}" ]]
      ;;
  esac
}

find_sample_file() {
  local root="${1}"
  local name="${2}"

  find "${root}" -maxdepth 3 -type f -name "${name}" | head -n 1
}
