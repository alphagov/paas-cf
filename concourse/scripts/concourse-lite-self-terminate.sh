#!/bin/bash
set -e
set -u

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
FLY_CMD=${FLY_CMD:-fly}

env=${DEPLOY_ENV:-$1}
pipeline="self-terminate"
config="${SCRIPT_DIR}/../pipelines/concourse-lite-self-terminate.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
deploy_env: ${env}
log_level: ${LOG_LEVEL:-}
EOF
}

generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)

$FLY_CMD -t "${FLY_TARGET}" unpause-pipeline --pipeline "${pipeline}"

