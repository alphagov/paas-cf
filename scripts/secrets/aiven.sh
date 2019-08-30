#!/usr/bin/env bash
export PASSWORD_STORE_DIR=${AIVEN_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}

if [ -n "${AIVEN_PASSWORD_STORE_HIGH_DIR:-}" ]; then
  export PASSWORD_STORE_DIR=${AIVEN_PASSWORD_STORE_HIGH_DIR}
fi
AIVEN_API_TOKEN=$(pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token")

cat << EOF
{
  "config": {
    "credhub_namespace": "${CREDHUB_NAMESPACE}",
    "s3_path": "s3://gds-paas-${DEPLOY_ENV}-state/aiven-secrets.yml"
  },
  "secrets": {
    "aiven_api_token": "${AIVEN_API_TOKEN}"
  }
}
EOF
