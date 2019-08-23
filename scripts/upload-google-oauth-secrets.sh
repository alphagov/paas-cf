#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${OAUTH_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry/}

GOOGLE_OAUTH_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_id")
GOOGLE_OAUTH_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_secret")

GRAFANA_AUTH_GOOGLE_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_id")
GRAFANA_AUTH_GOOGLE_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_secret")

GOOGLE_PAAS_ADMIN_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_id")
GOOGLE_PAAS_ADMIN_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_secret")

S3_SECRETS=$(mktemp secrets.yml.XXXXXX)
CREDHUB_SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm "${S3_SECRETS}"; rm "${CREDHUB_SECRETS}"' EXIT

cat > "${S3_SECRETS}" << EOF
---
secrets:
  google_oauth_client_id: ${GOOGLE_OAUTH_CLIENT_ID}
  google_oauth_client_secret: ${GOOGLE_OAUTH_CLIENT_SECRET}
  grafana_auth_google_client_id: ${GRAFANA_AUTH_GOOGLE_CLIENT_ID}
  grafana_auth_google_client_secret: ${GRAFANA_AUTH_GOOGLE_CLIENT_SECRET}
  google_paas_admin_client_id: ${GOOGLE_PAAS_ADMIN_CLIENT_ID}
  google_paas_admin_client_secret: ${GOOGLE_PAAS_ADMIN_CLIENT_SECRET}
EOF

cat > "${CREDHUB_SECRETS}" << EOF
---
credentials:
  - name: ${CREDHUB_NAMESPACE}google_oauth_client_id
    type: value
    value: ${GOOGLE_OAUTH_CLIENT_ID}
  - name: ${CREDHUB_NAMESPACE}google_oauth_client_secret
    type: value
    value: ${GOOGLE_OAUTH_CLIENT_SECRET}
  - name: ${CREDHUB_NAMESPACE}grafana_auth_google_client_id
    type: value
    value: ${GRAFANA_AUTH_GOOGLE_CLIENT_ID}
  - name: ${CREDHUB_NAMESPACE}grafana_auth_google_client_secret
    type: value
    value: ${GRAFANA_AUTH_GOOGLE_CLIENT_SECRET}
  - name: ${CREDHUB_NAMESPACE}google_paas_admin_client_id
    type: value
    value: ${GOOGLE_PAAS_ADMIN_CLIENT_ID}
  - name: ${CREDHUB_NAMESPACE}google_paas_admin_client_secret
    type: value
    value: ${GOOGLE_PAAS_ADMIN_CLIENT_SECRET}
EOF

aws s3 cp "${S3_SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/google-oauth-secrets.yml"

./scripts/credhub-import.sh "$(pwd)/${CREDHUB_SECRETS}"
