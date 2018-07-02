#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"
check_aws_account_used dev

API_URL="https://api.${DEPLOY_ENV}.dev.cloudpipeline.digital"

# shellcheck disable=SC2091
$("${SCRIPT_DIR}/show-cf-secrets.sh" cf_admin_password)

cf api "$API_URL"
cf login -u admin -p "${CF_ADMIN_PASSWORD}"
