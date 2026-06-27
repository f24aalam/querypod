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
INSTALL_LIB_DIR="/usr/lib/${APP_NAME}"
NATIVE_ASSET_MANIFEST="${BUILD_BUNDLE_DIR}/data/flutter_assets/NativeAssetsManifest.json"
ICON_SIZES=(16 24 32 48 64 128 256 512)

maintainer_name="${DEB_MAINTAINER_NAME:-$(git -C "${ROOT_DIR}" config user.name 2>/dev/null || true)}"
maintainer_email="${DEB_MAINTAINER_EMAIL:-$(git -C "${ROOT_DIR}" config user.email 2>/dev/null || true)}"
MAINTAINER="${maintainer_name:-QueryPod} <${maintainer_email:-opensource@example.invalid}>"

if [[ ! -f "${ICON_SOURCE}" ]]; then
  echo "Missing Linux app icon: ${ICON_SOURCE}" >&2
  echo "Put a square PNG there first. 512x512 is the recommended size." >&2
  exit 1
fi

if [[ ! -f "${DESKTOP_SOURCE}" ]]; then
  echo "Missing desktop entry template: ${DESKTOP_SOURCE}" >&2
  exit 1
fi

VERSION="${RELEASE_VERSION:-$(sed -nE 's/^version:[[:space:]]*([^+[:space:]]+)(\+.*)?$/\1/p' "${ROOT_DIR}/pubspec.yaml" | head -n 1)}"
if [[ -z "${VERSION}" ]]; then
  echo "Unable to read app version from pubspec.yaml" >&2
  exit 1
fi

PACKAGE_DIR="${DEB_BUILD_DIR}/${APP_NAME}_${VERSION}_${ARCH}"
OUTPUT_DEB="${DEB_BUILD_DIR}/${APP_NAME}_${VERSION}_${ARCH}.deb"
PACKAGE_LIB_DIR="${PACKAGE_DIR}${INSTALL_LIB_DIR}"
DOC_DIR="${PACKAGE_DIR}/usr/share/doc/${APP_NAME}"

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
install -d "${PACKAGE_LIB_DIR}"
install -d "${PACKAGE_DIR}/usr/bin"
install -d "${PACKAGE_DIR}/usr/share/applications"
install -d "${DOC_DIR}"

for size in "${ICON_SIZES[@]}"; do
  install -d "${PACKAGE_DIR}/usr/share/icons/hicolor/${size}x${size}/apps"
done

cp -R "${BUILD_BUNDLE_DIR}/." "${PACKAGE_LIB_DIR}/"

find "${PACKAGE_LIB_DIR}" -type d -exec chmod 755 {} +
find "${PACKAGE_LIB_DIR}" -type f -exec chmod 644 {} +
chmod 755 "${PACKAGE_LIB_DIR}/${APP_NAME}"

if [[ -f "${PACKAGE_LIB_DIR}/lib/libdartjni.so" ]] && [[ -f "${NATIVE_ASSET_MANIFEST}" ]]; then
  if ! grep -q 'libdartjni.so' "${NATIVE_ASSET_MANIFEST}"; then
    rm -f "${PACKAGE_LIB_DIR}/lib/libdartjni.so"
  fi
fi

runtime_bins=(
  "${PACKAGE_LIB_DIR}/${APP_NAME}"
  "${PACKAGE_LIB_DIR}/lib/libfile_selector_linux_plugin.so"
  "${PACKAGE_LIB_DIR}/lib/libflutter_secure_storage_linux_plugin.so"
  "${PACKAGE_LIB_DIR}/lib/liburl_launcher_linux_plugin.so"
)

if [[ -f "${PACKAGE_LIB_DIR}/lib/libdartjni.so" ]]; then
  runtime_bins+=("${PACKAGE_LIB_DIR}/lib/libdartjni.so")
fi

mkdir -p "${PACKAGE_DIR}/debian"
cat > "${PACKAGE_DIR}/debian/control" <<EOF
Source: ${APP_NAME}
Section: utils
Priority: optional
Maintainer: ${MAINTAINER}
Standards-Version: 4.6.2

Package: ${APP_NAME}
Architecture: ${ARCH}
Description: ${DISPLAY_NAME} desktop application
EOF

shlibs_output="$(
  cd "${PACKAGE_DIR}"
  dpkg-shlibdeps -O \
    -l"${PACKAGE_LIB_DIR}/lib" \
    "${runtime_bins[@]}"
)"

depends="${shlibs_output#shlibs:Depends=}"
depends="${depends//$'\n'/}"
rm -rf "${PACKAGE_DIR}/debian"

cat > "${PACKAGE_DIR}/DEBIAN/control" <<EOF
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: ${MAINTAINER}
Depends: ${depends}
Description: Desktop SQL workspace
 A desktop SQL workspace for local and remote databases.
EOF

cat > "${PACKAGE_DIR}/usr/bin/${APP_NAME}" <<EOF
#!/usr/bin/env bash
exec ${INSTALL_LIB_DIR}/${APP_NAME} "\$@"
EOF
chmod 755 "${PACKAGE_DIR}/usr/bin/${APP_NAME}"

install -m 644 "${DESKTOP_SOURCE}" "${PACKAGE_DIR}/usr/share/applications/${APP_ID}.desktop"

for size in "${ICON_SIZES[@]}"; do
  convert "${ICON_SOURCE}" -resize "${size}x${size}" \
    "${PACKAGE_DIR}/usr/share/icons/hicolor/${size}x${size}/apps/${APP_ID}.png"
done
find "${PACKAGE_DIR}/usr/share/icons" -type f -exec chmod 644 {} +

cat > "${DOC_DIR}/changelog" <<EOF
querypod (${VERSION}) unstable; urgency=medium

  * Package desktop release bundle.

 -- ${MAINTAINER}  $(date -R)
EOF
find "${PACKAGE_LIB_DIR}" -maxdepth 1 -type f -name "${APP_NAME}" -exec strip --strip-unneeded {} +
find "${PACKAGE_LIB_DIR}/lib" -maxdepth 1 -type f -name '*.so' -exec strip --strip-unneeded {} +
gzip -9 -n -f "${DOC_DIR}/changelog"
find "${DOC_DIR}" -type f -exec chmod 644 {} +

dpkg-deb --build --root-owner-group "${PACKAGE_DIR}" "${OUTPUT_DEB}"

echo "Created package: ${OUTPUT_DEB}"
