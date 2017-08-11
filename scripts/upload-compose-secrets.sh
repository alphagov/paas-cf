#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${COMPOSE_PASSWORD_STORE_DIR}

COMPOSE_API_KEY=$(pass "compose/${AWS_ACCOUNT}/access_token")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
compose_api_key: ${COMPOSE_API_KEY}
compose_access_token: ${COMPOSE_API_KEY}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/compose-secrets.yml"
