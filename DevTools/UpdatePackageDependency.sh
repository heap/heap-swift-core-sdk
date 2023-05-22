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
ROOT_DIR="${SCRIPT_DIR}/.."

TMP_DIR=$(mktemp -d -t heap-swift-core)
CHECKSUM_DIR="${TMP_DIR}/Checksum"

VERSION=$1

ZIP_FILE="heap-swift-core-interfaces-${VERSION}.zip"
ZIP_URL="https://cdn.heapanalytics.com/ios/${ZIP_FILE}"
ZIP_PATH="${TMP_DIR}/${ZIP_FILE}"

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

URL_PART="url: \"${ZIP_URL}\", // END HeapSwiftCoreInterfaces URL"
CHECKSUM_PART="checksum: \"${CHECKSUM}\" // END HeapSwiftCoreInterfaces checksum"

for PACKAGE_FILE in "${ROOT_DIR}/Package.swift" "${ROOT_DIR}/Development/Package.swift"; do
  echo "Updating ${PACKAGE_FILE}"

  sed -i '' \
    -e "s#url:.*END HeapSwiftCoreInterfaces URL#${URL_PART}#g" \
    -e "s#checksum:.*END HeapSwiftCoreInterfaces checksum#${CHECKSUM_PART}#g" \
    "${PACKAGE_FILE}"
done
