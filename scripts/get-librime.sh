#!/bin/bash
# Download the pinned prebuilt librime (macOS universal) into librime/dist.
# Artifacts come from rime/librime releases, same source Squirrel CI uses.
set -euo pipefail

cd "$(dirname "$0")/.."

LIBRIME_TAG="1.17.0"
LIBRIME_COMMIT="33e7814"
LIBRIME_SHA256="11d8dc663c6ec06d5ccb6111ba664a9e7b631b703ac6acd07cffbac664021850"
ARCHIVE_NAME="rime-${LIBRIME_COMMIT}-macOS-universal.tar.bz2"
DOWNLOAD_URL="https://github.com/rime/librime/releases/download/${LIBRIME_TAG}/${ARCHIVE_NAME}"

DIST_DIR="librime/dist"
if [ -f "${DIST_DIR}/lib/librime.1.dylib" ] && [ -f "${DIST_DIR}/include/rime_api.h" ]; then
  echo "librime already present at ${DIST_DIR}, skip download"
  exit 0
fi

mkdir -p librime
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Downloading ${DOWNLOAD_URL}"
curl -fL --retry 3 -o "${TMP_DIR}/${ARCHIVE_NAME}" "${DOWNLOAD_URL}"
echo "${LIBRIME_SHA256}  ${TMP_DIR}/${ARCHIVE_NAME}" | shasum -a 256 -c -

mkdir -p "${DIST_DIR}"
# the tarball wraps everything in a top-level dist/ directory
tar -xjf "${TMP_DIR}/${ARCHIVE_NAME}" -C "${DIST_DIR}" --strip-components=1
# the shipped dylib is only linker-signed, which codesign rejects when the
# dylib is embedded into the app bundle; force a proper ad-hoc signature
codesign -f -s - "${DIST_DIR}/lib/librime.1.dylib" 2>/dev/null || true
echo "librime unpacked into ${DIST_DIR}"
