#!/usr/bin/env bash
export PASSWORD_STORE_DIR=${PAGERDUTY_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}

ALERTMANAGER_PAGERDUTY_SERVICE_KEY=$(pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_service_key")

cat << EOF
{
  "config": {
    "credhub_namespace": "${CREDHUB_NAMESPACE}",
    "s3_path": "s3://gds-paas-${DEPLOY_ENV}-state/google-oauth-secrets.yml"
  },
  "secrets": {
    "alertmanager_pagerduty_service_key": "${ALERTMANAGER_PAGERDUTY_SERVICE_KEY}"
  }
}
EOF
