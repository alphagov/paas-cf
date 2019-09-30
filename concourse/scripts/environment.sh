#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)

DEPLOY_ENV=${1:-${DEPLOY_ENV:-}}
if [ -z "${DEPLOY_ENV}" ]; then
  echo "Must specify DEPLOY_ENV as \$1 or environment variable" 1>&2
  exit 1
fi

case $TARGET_CONCOURSE in
  deployer)
    CONCOURSE_URL="${CONCOURSE_URL:-https://deployer.${SYSTEM_DNS_ZONE_NAME}}"
    FLY_TARGET=${FLY_TARGET:-$DEPLOY_ENV}
    FLY_CMD="${PROJECT_DIR}/bin/fly"
    ;;
  bootstrap)
    CONCOURSE_URL="${CONCOURSE_URL:-http://localhost:8080}"
    FLY_TARGET="${FLY_TARGET:-${DEPLOY_ENV}-bootstrap}"
    FLY_CMD="${PROJECT_DIR}/bin/fly-bootstrap"
    ;;
  *)
    echo "Unrecognized TARGET_CONCOURSE: '${TARGET_CONCOURSE}'. Must be set to 'deployer' or 'bootstrap'" 1>&2
    exit 1
    ;;
esac

if [ "$USER" == "root" ] ; then
  # We are running in Concourse
  : "${CONCOURSE_WEB_PASSWORD:?CONCOURSE_WEB_PASSWORD must be set}"
  cat <<EOF
export CONCOURSE_WEB_USER=${CONCOURSE_WEB_USER:-admin}
export CONCOURSE_WEB_PASSWORD=${CONCOURSE_WEB_PASSWORD}
EOF
fi

cat <<EOF
export AWS_ACCOUNT=${AWS_ACCOUNT}
export DEPLOY_ENV=${DEPLOY_ENV}
export CONCOURSE_URL=${CONCOURSE_URL}
export FLY_CMD=${FLY_CMD}
export FLY_TARGET=${FLY_TARGET}
export API_ENDPOINT=https://api.${SYSTEM_DNS_ZONE_NAME}
EOF
