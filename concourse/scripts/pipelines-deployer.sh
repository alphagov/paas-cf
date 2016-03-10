#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=bootstrap
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

env=${DEPLOY_ENV}

generate_vars_file() {
   cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-dev}
vagrant_ip: ${VAGRANT_IP}
deploy_env: ${env}
tfstate_bucket: bucket=${env}-state
state_bucket: ${env}-state
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
concourse_atc_password: ${CONCOURSE_ATC_PASSWORD}
log_level: ${LOG_LEVEL:-}
paas_cf_tag_filter: ${PAAS_CF_TAG_FILTER:-}
EOF
}

generate_vars_file > /dev/null # Check for missing vars

for ACTION in create destroy; do
  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
    "${env}" "${ACTION}-deployer" \
    "${SCRIPT_DIR}/../pipelines/${ACTION}-deployer.yml" \
    <(generate_vars_file)
done
