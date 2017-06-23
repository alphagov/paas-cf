#!/bin/bash
#
# Required variables are:
# - DEPLOY_ENV
# - AWS_ACCOUNT

set -u
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Pipeline kick-off is enabled. Updating. (set ENABLE_MORNING_DEPLOYMENT=false to disable)"

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh")
"${SCRIPT_DIR}/fly_sync_and_login.sh"
FLY="$FLY_CMD -t ${FLY_TARGET}"

${FLY} trigger-job -j "create-cloudfoundry/pipeline-lock"
