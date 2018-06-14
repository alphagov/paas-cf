#!/bin/bash
#
# Required variables are:
# - DEPLOY_ENV
# - MAKEFILE_ENV_TARGET
# - SELF_UPDATE_PIPELINE
#
# Optional variables:
# - BRANCH
# - PIPELINES_TO_UPDATE

set -u
set -e

if [ ! -d "./paas-cf" ]; then
  echo "Resource paas-cf must be checkout"
  exit 1
fi

if [ "${SELF_UPDATE_PIPELINE}" != "true" ]; then
  echo "Self update pipeline is disabled. Skipping. (set SELF_UPDATE_PIPELINE=true to enable)"
else
  echo "Self update pipeline is enabled. Updating. (set SELF_UPDATE_PIPELINE=false to disable)"

  make -C ./paas-cf "${MAKEFILE_ENV_TARGET}" pipelines
fi
