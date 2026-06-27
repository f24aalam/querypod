#!/usr/bin/env bash

set -euo pipefail

APP_NAME="querypod"
DISPLAY_NAME="QueryPod"
APP_ID="me.aalam.querypod"
ARCH="amd64"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SOURCE="${ROOT_DIR}/packaging/linux/icon.png"
DESKTOP_SOURCE="${ROOT_DIR}/packaging/linux/${APP_ID}.desktop"
BUILD_BUNDLE_DIR="${ROOT_DIR}/build/linux/x64/release/bundle"
DEB_BUILD_DIR="${ROOT_DIR}/build/linux/deb"
ICON_SIZES=(16 24 32 48 64 128 256 512)

if [[ ! -f "${ICON_SOURCE}" ]]; then
  echo "Missing Linux app icon: ${ICON_SOURCE}" >&2
  echo "Put a square PNG there first. 512x512 is the recommended size." >&2
  exit 1
fi

if [[ ! -f "${DESKTOP_SOURCE}" ]]; then
  echo "Missing desktop entry template: ${DESKTOP_SOURCE}" >&2
  exit 1
fi

VERSION="$(sed -nE 's/^version:[[:space:]]*([^+[:space:]]+)(\+.*)?$/\1/p' "${ROOT_DIR}/pubspec.yaml" | head -n 1)"
if [[ -z "${VERSION}" ]]; then
  echo "Unable to read app version from pubspec.yaml" >&2
  exit 1
fi

PACKAGE_DIR="${DEB_BUILD_DIR}/${APP_NAME}_${VERSION}_${ARCH}"
OUTPUT_DEB="${DEB_BUILD_DIR}/${APP_NAME}_${VERSION}_${ARCH}.deb"

echo "Building Flutter Linux bundle..."
(
  cd "${ROOT_DIR}"
  flutter build linux --release
)

if [[ ! -x "${BUILD_BUNDLE_DIR}/${APP_NAME}" ]]; then
  echo "Expected built binary at ${BUILD_BUNDLE_DIR}/${APP_NAME}" >&2
  exit 1
fi

rm -rf "${PACKAGE_DIR}" "${OUTPUT_DEB}"

install -d "${PACKAGE_DIR}/DEBIAN"
install -d "${PACKAGE_DIR}/opt/${APP_NAME}"
install -d "${PACKAGE_DIR}/usr/bin"
install -d "${PACKAGE_DIR}/usr/share/applications"

for size in "${ICON_SIZES[@]}"; do
  install -d "${PACKAGE_DIR}/usr/share/icons/hicolor/${size}x${size}/apps"
done

cat > "${PACKAGE_DIR}/DEBIAN/control" <<EOF
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: Querypod
Depends: libgtk-3-0, libsecret-1-0
Description: ${DISPLAY_NAME} desktop application
EOF

cp -a "${BUILD_BUNDLE_DIR}/." "${PACKAGE_DIR}/opt/${APP_NAME}/"

cat > "${PACKAGE_DIR}/usr/bin/${APP_NAME}" <<EOF
#!/usr/bin/env bash
exec /opt/${APP_NAME}/${APP_NAME} "\$@"
EOF
chmod 755 "${PACKAGE_DIR}/usr/bin/${APP_NAME}"

install -m 644 "${DESKTOP_SOURCE}" "${PACKAGE_DIR}/usr/share/applications/${APP_ID}.desktop"

for size in "${ICON_SIZES[@]}"; do
  convert "${ICON_SOURCE}" -resize "${size}x${size}" \
    "${PACKAGE_DIR}/usr/share/icons/hicolor/${size}x${size}/apps/${APP_ID}.png"
done

dpkg-deb --build --root-owner-group "${PACKAGE_DIR}" "${OUTPUT_DEB}"

echo "Created package: ${OUTPUT_DEB}"
