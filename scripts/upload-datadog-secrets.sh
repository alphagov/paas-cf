#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${DATADOG_PASSWORD_STORE_DIR}

DATADOG_API_KEY=$(pass "datadog/${MAKEFILE_ENV_TARGET}/datadog_api_key")
DATADOG_APP_KEY=$(pass "datadog/${MAKEFILE_ENV_TARGET}/datadog_app_key")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
datadog_api_key: ${DATADOG_API_KEY}
datadog_app_key: ${DATADOG_APP_KEY}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/datadog-secrets.yml"
