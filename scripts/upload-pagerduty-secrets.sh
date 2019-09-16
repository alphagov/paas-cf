#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${PAGERDUTY_PASSWORD_STORE_DIR}

ALERTMANAGER_PAGERDUTY_24_7_SERVICE_KEY=$(pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_24_7_service_key")
ALERTMANAGER_PAGERDUTY_IN_HOURS_SERVICE_KEY=$(pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_in_hours_service_key")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
alertmanager_pagerduty_24_7_service_key: ${ALERTMANAGER_PAGERDUTY_24_7_SERVICE_KEY}
alertmanager_pagerduty_in_hours_service_key: ${ALERTMANAGER_PAGERDUTY_IN_HOURS_SERVICE_KEY}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/pagerduty-secrets.yml"
