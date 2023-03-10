#!/usr/bin/env bash
# DevTools/ReleaseFromRemoteBranch.sh - Helper for tagging the remote head of the repo
#
# Copyright (c) 2022 Heap Inc.
#
# Usage:
# ./DevTools/ReleaseFromRemoteBranch.sh [BRANCH]
# 
# make release_from_origin_main
#
# This makes it harder to accidentally tag the wrong commit or use the wrong version.

set -o errexit

BRANCH="${1:-main}"

TMP_DIR=$(mktemp -d -t heap-swift-core)
REPO_DIR="${TMP_DIR}/heap-swift-core"

REPO='git@github.com:heap/heap-swift-core.git'

echo "--- Cloning branch ${BRANCH} of ${REPO}"

git clone --depth 1 -b "${BRANCH}" "${REPO}" "${REPO_DIR}"

VERSION=$("${REPO_DIR}"/DevTools/LibraryVersions.py --print)

echo "--- Pushing tag ${VERSION} from branch ${BRANCH}"
cd  "${REPO_DIR}"

git tag "${VERSION}"
git push origin "${VERSION}"
