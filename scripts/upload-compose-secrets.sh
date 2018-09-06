#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${COMPOSE_PASSWORD_STORE_DIR}

if [ -n "${COMPOSE_PASSWORD_STORE_HIGH_DIR:-}" ]; then
  export PASSWORD_STORE_DIR=${COMPOSE_PASSWORD_STORE_HIGH_DIR}
fi
COMPOSE_API_KEY=$(pass "compose/${MAKEFILE_ENV_TARGET}/access_token")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
compose_api_key: ${COMPOSE_API_KEY}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/compose-secrets.yml"
