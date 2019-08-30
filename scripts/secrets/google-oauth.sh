#!/usr/bin/env bash
export PASSWORD_STORE_DIR=${OAUTH_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}

GOOGLE_OAUTH_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_id")
GOOGLE_OAUTH_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_secret")

GRAFANA_AUTH_GOOGLE_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_id")
GRAFANA_AUTH_GOOGLE_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_secret")

GOOGLE_PAAS_ADMIN_CLIENT_ID=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_id")
GOOGLE_PAAS_ADMIN_CLIENT_SECRET=$(pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_secret")

cat << EOF
{
  "config": {
    "credhub_namespace": "${CREDHUB_NAMESPACE}",
    "s3_path": "s3://gds-paas-${DEPLOY_ENV}-state/google-oauth-secrets.yml"
  },
  "secrets": {
    "google_oauth_client_id": "${GOOGLE_OAUTH_CLIENT_ID}",
    "google_oauth_client_secret": "${GOOGLE_OAUTH_CLIENT_SECRET}",
    "grafana_auth_google_client_id": "${GRAFANA_AUTH_GOOGLE_CLIENT_ID}",
    "grafana_auth_google_client_secret": "${GRAFANA_AUTH_GOOGLE_CLIENT_SECRET}",
    "google_paas_admin_client_id": "${GOOGLE_PAAS_ADMIN_CLIENT_ID}",
    "google_paas_admin_client_secret": "${GOOGLE_PAAS_ADMIN_CLIENT_SECRET}"
  }
}
EOF
