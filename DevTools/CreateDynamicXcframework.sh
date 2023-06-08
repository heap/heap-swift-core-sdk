#!/usr/bin/env bash
# DevTools/CreateInterfacesXcframework.sh - A helper to build HeapSwiftCoreInterfaces.xcframework
#
# Takes frameworks from build/xcframework.intermediates/{platform}.xcarchive, bundles them into
# build/xcframework/HeapSwiftCoreInterfaces.xcframework and zips it into
# build/xcframework/heap-swift-core-interfaces-{version}.zip
#
# This depends on DevTools/BuildInterfacesFramework.sh having been run first.
# 
# USAGE: ./DevTools/CreateInterfacesXcframework.sh VERSION
#
# - VERSION: The version string for the framework (in the zip file name).

set -o errexit

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

VERSION=$1
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR="${SCRIPT_DIR}/.."
BUILD_DIR="${ROOT_DIR}/build"
ARCHIVE_DIR="${BUILD_DIR}/xcframework.intermediates"
PRODUCT_NAME='HeapSwiftCore-Dynamic'

DEST_DIR="${BUILD_DIR}/xcframework"

FRAMEWORK_PATH="Products/usr/local/lib/${PRODUCT_NAME}.framework"

echo "--- Creating xcframework"

rm -rf "${DEST_DIR}"

xcodebuild -create-xcframework \
    -framework "${ARCHIVE_DIR}/iphoneos.xcarchive/${FRAMEWORK_PATH}" \
    -framework "${ARCHIVE_DIR}/iphonesimulator.xcarchive/${FRAMEWORK_PATH}" \
    -framework "${ARCHIVE_DIR}/catalyst.xcarchive/${FRAMEWORK_PATH}" \
    -output "${BUILD_DIR}/xcframework/HeapSwiftCore-Dynamic.xcframework"

cp "${ROOT_DIR}/LICENSE.txt" "${DEST_DIR}/LICENSE.txt"
cp "${ARCHIVE_DIR}/obj/GeneratedModuleMaps-iphonesimulator/HeapSwiftCore-Swift.h" "${DEST_DIR}/HeapSwiftCore-Swift.h"
cp -r "${ARCHIVE_DIR}/derived/SourcePackages/artifacts/development/HeapSwiftCoreInterfaces.xcframework" "${DEST_DIR}/HeapSwiftCoreInterfaces.xcframework"

cd "${DEST_DIR}"
zip -ry "heap-swift-core-dynamic-${VERSION}.zip" .
