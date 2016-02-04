#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

env=${DEPLOY_ENV-$1}
[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

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
EOF
}

for ACTION in create destroy; do
  trigger_file="${ACTION}-microbosh.trigger"
  generate_vars_file > /dev/null # Check for missing vars

  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
    "${env}" "${ACTION}-microbosh" \
    "${SCRIPT_DIR}/../pipelines/${ACTION}-microbosh.yml" \
    <(generate_vars_file)
done
