#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${PAGERDUTY_PASSWORD_STORE_DIR}

KEY=$(pass "pagerduty/${MAKEFILE_ENV_TARGET}/pagerduty_integration_key")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
pagerduty_integration_key: ${KEY}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/pagerduty-secrets.yml"
