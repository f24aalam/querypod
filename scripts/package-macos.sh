#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="QueryPod"
VERSION="$(sed -nE 's/^version:[[:space:]]*([^+[:space:]]+)(\+.*)?$/\1/p' "${ROOT_DIR}/pubspec.yaml" | head -n 1)"
RELEASE_TAG="${RELEASE_TAG:-v${VERSION}}"
DIST_DIR="${DIST_DIR:-${ROOT_DIR}/dist}"
APP_BUNDLE="${ROOT_DIR}/build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_PATH="${DIST_DIR}/querypod-${RELEASE_TAG}-macos-universal.dmg"

if [[ ! -d "${APP_BUNDLE}" ]]; then
  echo "Missing macOS app bundle: ${APP_BUNDLE}" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"

staging_dir="$(mktemp -d)"
trap 'rm -rf "${staging_dir}"' EXIT

cp -R "${APP_BUNDLE}" "${staging_dir}/${APP_NAME}.app"
ln -s /Applications "${staging_dir}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${staging_dir}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "${DMG_PATH}"
