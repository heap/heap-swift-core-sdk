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
BUILD_DIR="${SCRIPT_DIR}/../build"
ARCHIVE_DIR="${BUILD_DIR}/xcframework.intermediates"

DEST_DIR="${BUILD_DIR}/xcframework"

FRAMEWORK_PATH="Products/Library/Frameworks/HeapSwiftCoreInterfaces.framework"
SYMBOLS_PATH="dSYMs/HeapSwiftCoreInterfaces.framework.dSYM/Contents/Resources/DWARF/HeapSwiftCoreInterfaces"

rm -rf "${DEST_DIR}"

xcodebuild -create-xcframework \
    -framework "${ARCHIVE_DIR}/iphoneos.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/iphoneos.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/iphonesimulator.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/iphonesimulator.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/catalyst.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/catalyst.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/macosx.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/macosx.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/watchos.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/watchos.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/watchsimulator.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/watchsimulator.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/appletvos.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/appletvos.xcarchive/${SYMBOLS_PATH}" \
    -framework "${ARCHIVE_DIR}/appletvsimulator.xcarchive/${FRAMEWORK_PATH}" \
    -debug-symbols "${ARCHIVE_DIR}/appletvsimulator.xcarchive/${SYMBOLS_PATH}" \
    -output "${BUILD_DIR}/xcframework/HeapSwiftCoreInterfaces.xcframework"

cd "${DEST_DIR}"
zip -r "heap-swift-core-interfaces-${VERSION}.zip" .
