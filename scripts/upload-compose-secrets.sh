#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${COMPOSE_PASSWORD_STORE_DIR}

COMPOSE_ACCOUNT_ID=$(pass "compose/account_id")
COMPOSE_ACCESS_TOKEN=$(pass "compose/${AWS_ACCOUNT}/access_token")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
compose_account_id: ${COMPOSE_ACCOUNT_ID}
compose_access_token: ${COMPOSE_ACCESS_TOKEN}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/compose-secrets.yml"
