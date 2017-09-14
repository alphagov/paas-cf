#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${COMPOSE_PASSWORD_STORE_DIR}

COMPOSE_API_KEY=$(pass "compose/${AWS_ACCOUNT}/access_token")
COMPOSE_BILLING_EMAIL=$(pass "compose/billing/email_address")
COMPOSE_BILLING_PASSWORD=$(pass "compose/billing/password")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
compose_api_key: ${COMPOSE_API_KEY}
compose_billing_email: ${COMPOSE_BILLING_EMAIL}
compose_billing_password: ${COMPOSE_BILLING_PASSWORD}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/compose-secrets.yml"
