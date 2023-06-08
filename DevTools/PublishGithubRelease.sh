#!/usr/bin/env bash
# DevTools/PublishGithubRelease.sh - Publishes a release to GitHub
#
# Publishes the specified version as a GitHub release using the
# changelog to populate the release notes.
#
# USAGE: ./DevTools/PublishRelease.sh VERSION
#
# - VERSION: The version tag.

set -o errexit

VERSION=$1

TMP_DIR=$(mktemp -d -t heap-swift-core)
REPO_DIR="${TMP_DIR}/heap-swift-core"

REPO='git@github.com:heap/heap-swift-core-sdk.git'

echo "--- Cloning branch ${VERSION} of ${REPO}"

git clone --depth 1 -b "${VERSION}" "${REPO}" "${REPO_DIR}"

cd "${REPO_DIR}"

# Get all lines between `## [VERSION]` and the next `## `.
NOTES=$(awk "{print_line=found} /^## /{found=0;print_line=0} /^## \\[${VERSION}\\]/{found=1} print_line" CHANGELOG.md)

gh release create -t "${VERSION}" -n "${NOTES}" --verify-tag "${VERSION}"
