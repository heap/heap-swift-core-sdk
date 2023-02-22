#!/usr/bin/env bash
# DevTools/FixProtoImports.sh - Marks `import SwiftProtobuf` as non-exported API for release builds.
#
# This allows HeapSwiftCore to build with Library Evolution and produce a consistent ABI while consuming a library that doesn't.
# It is configured with an #if statement so test builds can still use SwiftProtobuf properties and their values.

function exit_with_error {
  echo "$@" 1>&2
  exit 1
}

function realpath {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

SCRIPT_DIR=$(dirname "$(realpath "$0")")
SRC_DIR="${SCRIPT_DIR}/../Development/Sources/HeapSwiftCore/Protobufs"
FILES="${SRC_DIR}/*.pb.swift"

LINE='import SwiftProtobuf'
REPLACEMENT='#if BUILD_HEAP_SWIFT_CORE_FOR_DEVELOPMENT\nimport SwiftProtobuf\n#else\n@_implementationOnly import SwiftProtobuf\n#endif'
PROCESSED='@_implementationOnly import SwiftProtobuf'


for file in $FILES; do
    echo -n "Processing $(basename "${file}")... "

    cat "${file}" | grep "${PROCESSED}" > /dev/null

    if [[ $? == 0 ]]; then
        echo 'ALREADY PROCESSED'
    else

        cat "${file}" | grep "${LINE}" > /dev/null
        if [[ $? == 0 ]]; then
            sed -i '' "s~${LINE}~${REPLACEMENT}~" "${file}" > /dev/null
            echo 'TRANSFORMED'
        else
            echo 'NO IMPORT'
        fi
    fi
done