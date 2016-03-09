#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

env=${DEPLOY_ENV}

extract_cf_version(){
  set -u
  manifest=$1
  ruby -e "require 'yaml'; \
    puts YAML.load(STDIN.read)['releases'].select { |item| item['name'] == 'cf' }.first['version']" < "$manifest"
}

cf_release_version=$(extract_cf_version "${SCRIPT_DIR}"/../../manifests/cf-manifest/deployments/000-base-cf-deployment.yml)

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-dev}
deploy_env: ${env}
state_bucket: ${env}-state
pipeline_trigger_file: ${trigger_file}
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
debug: ${DEBUG:-}
cf-release-version: v${cf_release_version}
EOF
}

trigger_file="failure-testing.trigger"
generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
  "${env}" "failure-testing" \
  "${SCRIPT_DIR}"/../pipelines/failure-testing.yml \
  <(generate_vars_file)
