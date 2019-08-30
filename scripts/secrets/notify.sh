#!/usr/bin/env bash
export PASSWORD_STORE_DIR=${NOTIFY_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}

NOTIFY_API_KEY="$(pass "notify/${MAKEFILE_ENV_TARGET}/api_key")"

cat << EOF
{
  "config": {
    "credhub_namespace": "${CREDHUB_NAMESPACE}",
    "s3_path": "s3://gds-paas-${DEPLOY_ENV}-state/notify-secrets.yml"
  },
  "secrets": {
    "notify_api_key": "${NOTIFY_API_KEY}"
  }
}
EOF
