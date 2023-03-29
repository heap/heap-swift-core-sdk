#!/usr/bin/env bash
# DevTools/RecreateInterfacesProject.sh - Creates a project for building HeapSwiftCoreInterfaces.xcframework
#
# Destination is at build/interfaces/HeapSwiftCoreInterfaces.xcodeproj

set -o errexit

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

SCRIPT_DIR=$(dirname "$(realpath "$0")")
RESOURCE_DIR="${SCRIPT_DIR}/Resources"
SOURCES_DIR="${SCRIPT_DIR}/../Development/Sources"
PROJECT_DIR="${SCRIPT_DIR}/../build/interfaces"

rm -rf "${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}/Sources"

rsync -r "${SOURCES_DIR}/" "${PROJECT_DIR}/Sources/"
cp "${RESOURCE_DIR}/Package-HeapSwiftCoreInterfaces.swift" "${PROJECT_DIR}/Package.swift"

cd "${PROJECT_DIR}" && swift package generate-xcodeproj > /dev/null
