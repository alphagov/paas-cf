#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

eval "$(make -C ./../../../../../ dev showenv)"

GOPATH="$(realpath "${SCRIPT_DIR}/../../../../")"
export GOPATH

export SKIP_SSL_VALIDATION=true
export APPS_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudapps.digital
export SYSTEM_DNS_ZONE_NAME=${DEPLOY_ENV}.dev.cloudpipeline.digital
export CONCOURSE_WEB_USERNAME=${CONCOURSE_WEB_USER}
export CONCOURSE_WEB_URL=${CONCOURSE_URL}
export CF_USER=admin
export CF_PASS=${CF_ADMIN_PASSWORD}
export PIPELINE_TRIGGER_VERSION=${PIPELINE_TRIGGER_VERSION:-0.0.1}

./run_tests.sh
