#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${OAUTH_PASSWORD_STORE_DIR}

GOOGLE_OAUTH_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_id")
GOOGLE_OAUTH_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_secret")

GRAFANA_AUTH_GOOGLE_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_id")
GRAFANA_AUTH_GOOGLE_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_secret")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "${SECRETS}" << EOF
---
secrets:
  google_oauth_client_id: ${GOOGLE_OAUTH_CLIENT_ID}
  google_oauth_client_secret: ${GOOGLE_OAUTH_CLIENT_SECRET}
  grafana_auth_google_client_id: ${GRAFANA_AUTH_GOOGLE_CLIENT_ID}
  grafana_auth_google_client_secret: ${GRAFANA_AUTH_GOOGLE_CLIENT_SECRET}
EOF

aws s3 cp "${SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/google-oauth-secrets.yml"
