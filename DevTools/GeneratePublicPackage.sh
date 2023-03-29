#!/usr/bin/env bash
# DevTools/GeneratePublicPackage.sh - Updates Package.swift with the current version of HeapSwiftCoreInterfaces from the CDN.

set -o errexit

function exit_with_error {
  echo "$@" 1>&2
  exit 1
}

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

SCRIPT_DIR=$(dirname "$(realpath "$0")")
BUILD_DIR="${SCRIPT_DIR}/../build"
RESOURCE_DIR="${SCRIPT_DIR}/Resources"
DEST_DIR="${SCRIPT_DIR}/.."

TMP_DIR=$(mktemp -d -t heap-swift-core)
CHECKSUM_DIR="${TMP_DIR}/Checksum"

VERSION=$1

ZIP_FILE="heap-swift-core-interfaces-${VERSION}.zip"
ZIP_URL="https://cdn.heapanalytics.com/ios/${ZIP_FILE}"
ZIP_PATH="${TMP_DIR}/${ZIP_FILE}"

SOURCE_PACKAGE_FILE="${RESOURCE_DIR}/Package-HeapSwiftCore.swift"
BUILD_PACKAGE_FILE="${BUILD_DIR}/Package-HeapSwiftCore.swift"
DEST_PACKAGE_FILE="${DEST_DIR}/Package.swift"

echo "${SOURCE_PACKAGE_FILE}"

echo '+++ Preparing Package.swift'

echo "Using ${TMP_DIR}"

echo "Downloading ${ZIP_FILE}"

curl -o "$ZIP_PATH" "https://cdn.heapanalytics.com/ios/${ZIP_FILE}"

# Must be in a valid swift project to generate a checksum for some reason.
mkdir "${CHECKSUM_DIR}"
cd "${CHECKSUM_DIR}"
swift package init > /dev/null
CHECKSUM=$(swift package compute-checksum "${ZIP_PATH}")

echo "Computed checksum ${CHECKSUM}"

mkdir -p "${BUILD_DIR}"
sed "s#{URL}#${ZIP_URL}#;s#{CHECKSUM}#${CHECKSUM}#;" "${SOURCE_PACKAGE_FILE}" > "${BUILD_PACKAGE_FILE}"

echo "Generated build file"
cat "${BUILD_PACKAGE_FILE}"
cp "${BUILD_PACKAGE_FILE}" "${DEST_PACKAGE_FILE}"
