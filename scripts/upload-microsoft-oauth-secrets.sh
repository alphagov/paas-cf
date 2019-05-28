#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${OAUTH_PASSWORD_STORE_DIR}

MICROSOFT_OAUTH_TENANT_ID=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/tenant_id")
MICROSOFT_OAUTH_CLIENT_ID=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_id")
MICROSOFT_OAUTH_CLIENT_SECRET=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_secret")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
secrets:
  microsoft_oauth_tenant_id: ${MICROSOFT_OAUTH_TENANT_ID}
  microsoft_oauth_client_id: ${MICROSOFT_OAUTH_CLIENT_ID}
  microsoft_oauth_client_secret: ${MICROSOFT_OAUTH_CLIENT_SECRET}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/microsoft-oauth-secrets.yml"
