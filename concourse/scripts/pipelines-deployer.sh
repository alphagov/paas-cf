#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=bootstrap
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

# shellcheck source=./concourse/scripts/lib/datadog.sh
. "${SCRIPT_DIR}/lib/datadog.sh"

env=${DEPLOY_ENV}

get_datadog_secrets

generate_vars_file() {
   cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-dev}
vagrant_ip: ${VAGRANT_IP}
deploy_env: ${env}
tfstate_bucket: bucket=${env}-state
state_bucket: ${env}-state
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
concourse_atc_password: ${CONCOURSE_ATC_PASSWORD}
log_level: ${LOG_LEVEL:-}
paas_cf_tag_filter: ${PAAS_CF_TAG_FILTER:-}
system_dns_zone_name: ${SYSTEM_DNS_ZONE_NAME}
aws_account: ${AWS_ACCOUNT:-dev}
datadog_api_key: ${datadog_api_key:-}
enable_datadog: ${ENABLE_DATADOG}
concourse_auth_duration: ${CONCOURSE_AUTH_DURATION:-24h}
EOF
}

generate_vars_file > /dev/null # Check for missing vars

generate_manifest_file() {
  if [ -z "${SKIP_COMMIT_VERIFICATION:-}" ] ; then
    gpg_ids="[$(xargs < "${SCRIPT_DIR}/../../.gpg-id" | tr ' ' ',')]"
  else
    gpg_ids="[]"
  fi

  # This exists because concourse does not support multiline value interpolation by design
  sed -e "s/{{gpg_ids}}/${gpg_ids}/" < "${SCRIPT_DIR}/../pipelines/${ACTION}-deployer.yml"
}

for ACTION in create destroy; do
  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
    "${env}" "${ACTION}-deployer" \
    <(generate_manifest_file) \
    <(generate_vars_file)
done
