#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${OAUTH_PASSWORD_STORE_DIR}

OAUTH_CLIENT_ID=$(pass "google/${AWS_ACCOUNT}/oauth/client_id")
OAUTH_CLIENT_SECRET=$(pass "google/${AWS_ACCOUNT}/oauth/client_secret")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
secrets:
  google_oauth_client_id: ${OAUTH_CLIENT_ID}
  google_oauth_client_secret: ${OAUTH_CLIENT_SECRET}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/google-oauth-secrets.yml"
