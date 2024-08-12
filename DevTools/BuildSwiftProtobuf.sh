#!/usr/bin/env bash

set -o errexit

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR="${SCRIPT_DIR}/.."
BUILD_DIR="${ROOT_DIR}/build"

TAG=$(jq -r '.object.pins[] | select(.package == "SwiftProtobuf") | .state.version' "${ROOT_DIR}/Package.resolved")

echo "--- Building Swift Protobuf ${TAG}"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

if [[ ! -d "${BUILD_DIR}/swift-protobuf" ]]; then
    git clone https://github.com/apple/swift-protobuf.git
fi

cd swift-protobuf
git fetch

git checkout "tags/${TAG}"
swift build -c release
