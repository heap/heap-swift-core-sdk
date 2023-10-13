#!/usr/bin/env bash
# DevTools/upload-to-s3.sh - Uploads a file to S3.
#
# Usage:
# ./DevTools/ReleaseFromRemoteBranch.sh LOCAL_FILE_PATH VERSION BUCKET KEY
#
# - LOCAL_FILE_PATH: The file to upload.
# - VERSION: The library version, stored as metadata in S3.
# - BUCKET: The S3 bucket, e.g. heapcdn.
# - KEY: The S3 key / path on the CDN.

set -o errexit

function exit_with_error {
  echo "$@" 1>&2
  exit 1
}

function s3_object_exists {
  local bucket=$1
  local key=$2
  local output=
  
  output=$(aws s3 ls "s3://${bucket}/${key}")
  if [[ -z "${output}" ]]; then return 1; fi
}

function s3_put_object {
  local local_file_path=$1
  local version=$2
  local bucket=$3
  local key=$4
  aws s3 cp "${local_file_path}" "s3://${bucket}/${key}" \
    --cache-control 'public, max-age=1800' \
    --content-type 'application/zip' \
    --metadata "version=${version}"
}

LOCAL_FILE_PATH=$1
VERSION=$2
BUCKET=$3
KEY=$4

if [[ -z "${LOCAL_FILE_PATH}" ||  -z "${VERSION}" || -z "${BUCKET}" || -z "${KEY}" ]]
then
  exit_with_error "USAGE: $0 LOCAL_FILE_PATH VERSION BUCKET KEY"
fi

if [[ ! -f "${LOCAL_FILE_PATH}" ]]
then
  exit_with_error "File not found at ${LOCAL_FILE_PATH}. Aborting."
fi

if s3_object_exists "${BUCKET}" "${KEY}"
then
  exit_with_error "The file s3://${BUCKET}/${KEY} already exists. Aborting."
fi

echo "Uploading ${LOCAL_FILE_PATH} to s3://${BUCKET}/${KEY}"
s3_put_object "${LOCAL_FILE_PATH}" "${VERSION}" "${BUCKET}" "${KEY}"
