#!/usr/bin/env bash
#
# Utility script to send a metric to the observability system.

set -o errexit
set -o nounset
set -o pipefail

#
# IMPLEMENTATION FUNCTIONS
#

readonly _EVENT_TYPE="$1" # "build"|"deploy_ecs"|"stop_ecs"
readonly _SERVICE="${2:-}"    # ECS service name or build slug

readonly _TITLE="Buildkite"
TAGS="buildkite_slug:${_SERVICE}"
if [[ "${_EVENT_TYPE}" =~ "ecs" ]] && [[ "${_SERVICE}" != "" ]]; then
  TAGS+=",ecs_service:${_SERVICE}"
fi

#
# MAIN EXECUTION
#

# By consolidating build-step commands, this script is no longer only invoked on "develop", so add
# conditional inside to only emit for that branch.
if [ "${BUILDKITE_BRANCH}" = "develop" ]; then
  echo "heap.buildkite.${_EVENT_TYPE}:1|c|#${TAGS}" >/dev/udp/localhost/8125
fi
