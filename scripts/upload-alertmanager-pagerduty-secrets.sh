#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${ALERTMANAGER_PAGERDUTY_PASSWORD_STORE_DIR}

KEY=$(pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_service_key")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
alertmanager_pagerduty_service_key: ${KEY}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/alertmanager-pagerduty-secrets.yml"
