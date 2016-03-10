#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=bootstrap
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

env=${DEPLOY_ENV}
pipeline="self-terminate"
config="${SCRIPT_DIR}/../pipelines/concourse-lite-self-terminate.yml"

generate_vars_file() {
   cat <<EOF
---
deploy_env: ${env}
log_level: ${LOG_LEVEL:-}
EOF
}

generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)
