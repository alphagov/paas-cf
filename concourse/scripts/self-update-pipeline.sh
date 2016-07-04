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

if [ ! -d "./paas-cf" ] || [ ! -f "concourse-manifest/concourse-manifest.yml" ]; then
  echo "Resources paas-cf and concourse-manifest must be checkout"
  exit 1
fi

if [ "${SELF_UPDATE_PIPELINE}" != "true" ]; then
  echo "Self update pipeline is disabled. Skipping. (set SELF_UPDATE_PIPELINE=true to enable)"
else
  echo "Self update pipeline is enabled. Updating. (set SELF_UPDATE_PIPELINE=false to disable)"

  VAL_FROM_YAML=$(pwd)/paas-cf/concourse/scripts/val_from_yaml.rb
  CONCOURSE_ATC_PASSWORD=$("$VAL_FROM_YAML" jobs.concourse.properties.basic_auth_password concourse-manifest/concourse-manifest.yml)
  export CONCOURSE_ATC_PASSWORD

  make -C ./paas-cf "${MAKEFILE_ENV_TARGET}" pipelines
fi
