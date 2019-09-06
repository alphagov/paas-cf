#!/bin/sh
#
# Upload the S3 object with the credentials and configuration
# from the environment or paas-pass.
#
# Usage:
#
#  AWS_ACCOUNT=dev LOGIT_PASSWORD_STORE_DIR=~/.paas-pass DEPLOY_ENV=hector
#   ./scripts/upload-logit-config.sh

set -eu

setup_env() {
  export PASSWORD_STORE_DIR=${LOGIT_PASSWORD_STORE_DIR}
  CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}
  S3_URI="s3://gds-paas-${DEPLOY_ENV}-state/logit-secrets.yml"
}

get_creds_from_env_or_pass() {
  setup_env
  LOGIT_SYSLOG_ADDRESS="${LOGIT_SYSLOG_ADDRESS:-$(pass "logit/${AWS_ACCOUNT}/syslog_address")}"
  LOGIT_SYSLOG_PORT="${LOGIT_SYSLOG_PORT:-$(pass "logit/${AWS_ACCOUNT}/syslog_port")}"
  LOGIT_CA_CERT="${LOGIT_CA_CERT:-$(pass "logit/${AWS_ACCOUNT}/ca_cert")}"
  LOGIT_ELASTICSEARCH_URL="${LOGIT_ELASTICSEARCH_URL:-$(pass "logit/${AWS_ACCOUNT}/elasticsearch_url")}"
  LOGIT_ELASTICSEARCH_API_KEY="${LOGIT_ELASTICSEARCH_API_KEY:-$(pass "logit/${AWS_ACCOUNT}/elasticsearch_api_key")}"
}
upload_s3() {
  cat << EOF | aws s3 cp - "${secrets_uri}"
---
meta:
  logit:
    syslog_address: ${LOGIT_SYSLOG_ADDRESS}
    syslog_port: ${LOGIT_SYSLOG_PORT}
    elasticsearch_url: ${LOGIT_ELASTICSEARCH_URL}
    elasticsearch_api_key: ${LOGIT_ELASTICSEARCH_API_KEY}
    ca_cert: |
$(echo "${LOGIT_CA_CERT}" | sed 's/^/      /')
EOF

}
upload_credhub() {

}
upload() {
  setup_env
  get_creds_from_env_or_pass
  upload_s3
  upload_credhub
}

upload
echo "upload: Logit secrets        to ${secrets_uri}"
