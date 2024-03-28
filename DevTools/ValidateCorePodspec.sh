#!/bin/bash

set -o errexit

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

POD_NAME=HeapSwiftCore
TEST_PROJECT=ReleaseTester

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="${SCRIPT_DIR}/.."

TEMP_DIR="${ROOT_DIR}/build/pod-test"
rm -rf "${TEMP_DIR}" || true
mkdir -p "${TEMP_DIR}"

echo "--- Updating pod repo"
pod repo update trunk

echo "--- Linting ${POD_NAME}.podspec"

pod lib lint --allow-warnings "${POD_NAME}.podspec"
# WARNING: The above line fails on more recent versions of Xcode because they
# broke macOS 10.9 support, which is what SwiftProtobuf specifies.

echo "--- Testing ${POD_NAME}.podspec in ${TEST_PROJECT}"

echo "Rsyncing the release test project into ${TEMP_DIR}"
mkdir "${TEMP_DIR}/${TEST_PROJECT}"
rsync -a --delete "${SCRIPT_DIR}/Resources/${TEST_PROJECT}/" "${TEMP_DIR}/${TEST_PROJECT}/"

echo "Running pod install"
cd "${TEMP_DIR}/${TEST_PROJECT}"
pod install

echo "Building the workspace"

set -o pipefail && xcodebuild \
    -workspace "${TEST_PROJECT}.xcworkspace" \
    -scheme "${TEST_PROJECT}" \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    | xcbeautify
