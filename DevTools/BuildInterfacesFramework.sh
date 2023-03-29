#!/usr/bin/env bash
# DevTools/BuildInterfacesFramework.sh - A helper to build HeapSwiftCoreInterfaces.framework
#
# Builds frameworks for all supported SDKs, placing them in
# build/xcframework.intermediates/{platform}.xcarchive
#
# USAGE: ./DevTools/BuildInterfacesFramework.sh VERSION
#
# - VERSION: The version string for the framework (in Info.plist).

set -o errexit

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

VERSION=$1
SCRIPT_DIR=$(dirname "$(realpath "$0")")
BUILD_DIR="${SCRIPT_DIR}/../build"
PROJECT_DIR="${SCRIPT_DIR}/../build/interfaces"
ARCHIVE_DIR="${BUILD_DIR}/xcframework.intermediates"

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
            -scheme HeapSwiftCoreInterfaces-Package \
            -configuration Release \
            -destination "${destination}" \
            -archivePath "${ARCHIVE_DIR}/${archive}.xcarchive" \
            -sdk "${sdk}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            SUPPORTS_MACCATALYST=YES \
            MARKETING_VERSION="${VERSION}" \
            | xcbeautify && SUCCESS=true;
        ATTEMPT=$((ATTEMPT+1));
    done;

    if [ -z "$SUCCESS" ]; then return 1; fi
}

rm -rf "${ARCHIVE_DIR}"

build_project iphonesimulator  iphonesimulator  "generic/platform=iOS Simulator"
build_project iphoneos         iphoneos         "generic/platform=iOS"
build_project catalyst         iphoneos         "generic/platform=macOS,variant=Mac Catalyst"
build_project macosx           macosx           "generic/platform=macOS"

build_project appletvos        appletvos        "generic/platform=tvOS"
build_project appletvsimulator appletvsimulator "generic/platform=tvOS Simulator"
build_project watchos          watchos          "generic/platform=watchOS"
build_project watchsimulator   watchsimulator   "generic/platform=watchOS Simulator"
