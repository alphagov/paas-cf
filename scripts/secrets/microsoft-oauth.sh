#!/usr/bin/env bash
export PASSWORD_STORE_DIR=${OAUTH_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}

MICROSOFT_OAUTH_TENANT_ID=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/tenant_id")
MICROSOFT_OAUTH_CLIENT_ID=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_id")
MICROSOFT_OAUTH_CLIENT_SECRET=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_secret")

MICROSOFT_ADMINOIDC_TENANT_ID=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/tenant_id")
MICROSOFT_ADMINOIDC_CLIENT_ID=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/client_id")
MICROSOFT_ADMINOIDC_CLIENT_SECRET=$(pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/client_secret")

cat << EOF
{
  "config": {
    "credhub_namespace": "${CREDHUB_NAMESPACE}",
    "s3_path": "s3://gds-paas-${DEPLOY_ENV}-state/microsoft-oauth-secrets.yml"
  },
  "secrets": {
    "microsoft_oauth_tenant_id": "${MICROSOFT_OAUTH_TENANT_ID}",
    "microsoft_oauth_client_id": "${MICROSOFT_OAUTH_CLIENT_ID}",
    "microsoft_oauth_client_secret": "${MICROSOFT_OAUTH_CLIENT_SECRET}",
    "microsoft_adminoidc_tenant_id": "${MICROSOFT_ADMINOIDC_TENANT_ID}",
    "microsoft_adminoidc_client_id": "${MICROSOFT_ADMINOIDC_CLIENT_ID}",
    "microsoft_adminoidc_client_secret": "${MICROSOFT_ADMINOIDC_CLIENT_SECRET}"
  }
}
EOF
