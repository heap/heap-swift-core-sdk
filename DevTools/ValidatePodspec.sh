#!/bin/bash

set -o errexit

POD_NAME=$1
TEST_PROJECT=$2
TEMP_DIR=$(mktemp -d -t heap-swift-core)

# Get the absolute path to the podspec file two levels up
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PODSPEC_PATH="$(realpath "${SCRIPT_DIR}/../${POD_NAME}.podspec")"

# Get the version from the podspec file
VERSION=$("${SCRIPT_DIR}/LibraryVersions.py" --print --library="${POD_NAME}")

# Copy example project to temp folder
echo "Rsyncing the release test project into the temp directory ${TEMP_DIR}"
rsync -a --delete "${SCRIPT_DIR}/Resources/${TEST_PROJECT}/" "${TEMP_DIR}"/

# Copy podspec into versioned folder in cloned repo folder
echo "--- Pushing ${POD_NAME}.podspec version ${VERSION} to pre-release-cocoapods"
pod repo push pre-release-cocoapods "${PODSPEC_PATH}" --allow-warnings

# Create and update the Podfile
cat << EOF > "${TEMP_DIR}"/Podfile
source 'git@github.com:heap/pre-release-cocoapods.git'
source 'https://cdn.cocoapods.org/'
target '${TEST_PROJECT}' do
  use_frameworks!
  pod '${POD_NAME}', '${VERSION}'
end
EOF

echo "Running pod install"
cd "${TEMP_DIR}" 
pod install
echo "Building the workspace"
echo "--- Testing ${POD_NAME}.podspec version ${VERSION} in ${TEST_PROJECT}"
set -o pipefail && xcodebuild \
    -workspace "${TEST_PROJECT}.xcworkspace" \
    -scheme "${TEST_PROJECT}" \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    | xcbeautify
