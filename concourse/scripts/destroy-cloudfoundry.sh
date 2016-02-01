#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

env=${DEPLOY_ENV-$1}
pipeline="destroy-cloudfoundry"
config="${SCRIPT_DIR}/../pipelines/destroy-cloudfoundry.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
account: ${AWS_ACCOUNT:-dev}
deploy_env: ${env}
state_bucket: ${env}-state
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
debug: ${DEBUG:-}
EOF
}
generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)
