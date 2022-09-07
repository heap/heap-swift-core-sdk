#!/usr/bin/env bash
#
# Tool to produce more correct `monorepo-diff` git diffs.

set -o errexit
set -o nounset
set -o pipefail

# Validate mode argument
mode=${1:-unspecified}
case "${mode}" in
  # NOTE: do not replace this curated selection with a more general ability to
  # pass filter arguments into this script! Having explicit validation of "useful"
  # filter modes creates a strong API to express intent which makes maintaining
  # this code easier.
  "all")
    # Do not filter; include all files including deleted files
    filter=""
    ;;
  "existing-files")
    # Include only results that represent accessible files in the current commit
    filter="d"
    ;;
  *)
    echo "Mode '${mode}' is not a valid diff mode."
    exit 1
    ;;
esac

# Assumption: on the default branch (`develop`) and `master` changes are squashed into single commits
BASE="HEAD~1"
if [ "${BUILDKITE_BRANCH}" != "${BUILDKITE_PIPELINE_DEFAULT_BRANCH}" ] && [ "${BUILDKITE_BRANCH}" != "master" ]; then
  # Note that Buildkite fetches only the PR head, which can leave the `develop` cursor
  # in the past leading to mis-identification of the `merge-base` as a much older commit
  git fetch origin "${BUILDKITE_PIPELINE_DEFAULT_BRANCH}"
  BASE=$(git merge-base "origin/${BUILDKITE_PIPELINE_DEFAULT_BRANCH}" HEAD)
fi

# Produce output for the `monorepo-diff` buildkite plugin to consume
if [ -z "${filter}" ]; then
  git diff --name-only "${BASE}"..HEAD
else
  git diff --name-only "${BASE}"..HEAD --diff-filter="${filter}"
fi
