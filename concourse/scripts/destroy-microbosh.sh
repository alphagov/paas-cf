#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
FLY_TARGET=${FLY_TARGET:-$ATC_URL}
FLY_CMD=${FLY_CMD:-fly}

env=${DEPLOY_ENV-$1}
pipeline="destroy-microbosh"
config="${SCRIPT_DIR}/../pipelines/destroy-microbosh.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
deploy_env: ${env}
state_bucket: ${env}-state
pipeline_name: ${pipeline}
pipeline_trigger_file: ${pipeline}.trigger
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
debug: ${DEBUG:-}
EOF
}

generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)

