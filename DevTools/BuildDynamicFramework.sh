#!/usr/bin/env bash
# DevTools/BuildDynamicFramework.sh - A helper to build HeapSwiftCore-Dynamic.framework
#
# Builds frameworks for all supported SDKs, placing them in
# build/xcframework.intermediates/{platform}.xcarchive
#
# USAGE: ./DevTools/BuildDynamicFramework.sh VERSION
#
# - VERSION: The version string for the framework (in Info.plist).

set -o errexit

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

VERSION=$1
SCRIPT_DIR=$(dirname "$(realpath "$0")")
BUILD_DIR="${SCRIPT_DIR}/../build"
PROJECT_DIR="${SCRIPT_DIR}/../Development"
ARCHIVE_DIR="${BUILD_DIR}/xcframework.intermediates"
SYMROOT="${ARCHIVE_DIR}/sym"
OBJROOT="${ARCHIVE_DIR}/obj"
DERIVED_DATA_DIR="${ARCHIVE_DIR}/derived"

cd "${PROJECT_DIR}"

function build_project {
    local archive=$1
    local sdk=$2
    local destination=$3

    echo "--- Building for ${archive}"

    local ATTEMPT=0;
    local MAX_ATTEMPTS=3;
    local SUCCESS=

    while [ -z "${SUCCESS}" ] && [ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]; do
        set -o pipefail && xcodebuild archive \
            -scheme HeapSwiftCore-Dynamic \
            -configuration Release \
            -destination "${destination}" \
            -archivePath "${ARCHIVE_DIR}/${archive}.xcarchive" \
            -sdk "${sdk}" \
            -derivedDataPath "${DERIVED_DATA_DIR}" \
            SYMROOT="${SYMROOT}" \
            OBJROOT="${OBJROOT}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            SUPPORTS_MACCATALYST=YES \
            MARKETING_VERSION="${VERSION}" \
            SWIFT_INSTALL_OBJC_HEADER=YES \
            SWIFT_INSTALL_MODULE=YES \
            | xcbeautify && SUCCESS=true;
        ATTEMPT=$((ATTEMPT+1));
    done;

    if [ -z "$SUCCESS" ]; then return 1; fi
}

rm -rf "${ARCHIVE_DIR}"

build_project iphonesimulator  iphonesimulator  "generic/platform=iOS Simulator"
build_project iphoneos         iphoneos         "generic/platform=iOS"
build_project catalyst         iphoneos         "generic/platform=macOS,variant=Mac Catalyst"
