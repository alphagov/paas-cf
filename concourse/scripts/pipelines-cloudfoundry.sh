#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/datadog.sh"

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/compose.sh"

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/aiven.sh"

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/google-oauth.sh"

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/notify.sh"

download_git_id_rsa() {
  git_id_rsa_file=$(mktemp -t id_rsa.XXXXXX)

  aws s3 cp "s3://${state_bucket}/git_id_rsa" "${git_id_rsa_file}"

  git_id_rsa=$(cat "${git_id_rsa_file}")

  rm -f "${git_id_rsa_file}"
}

get_git_concourse_pool_clone_full_url_ssh() {
  tfstate_file=$(mktemp -t tfstate.XXXXXX)

  aws s3 cp "s3://${state_bucket}/concourse.tfstate" "${tfstate_file}"

  git_concourse_pool_clone_full_url_ssh=$(ruby < "${tfstate_file}" -rjson -e \
    'puts JSON.load(STDIN)["modules"][0]["outputs"]["git_concourse_pool_clone_full_url_ssh"]["value"]'
  )

  rm -f "${tfstate_file}"
}

prepare_environment() {
  "${SCRIPT_DIR}/fly_sync_and_login.sh"

  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

  pipelines_to_update="${PIPELINES_TO_UPDATE:-create-cloudfoundry deployment-kick-off destroy-cloudfoundry autodelete-cloudfoundry}"
  bosh_az=${BOSH_AZ:-${AWS_DEFAULT_REGION}a}

  state_bucket=gds-paas-${DEPLOY_ENV}-state

  if [ "${SKIP_COMMIT_VERIFICATION:-}" = "true" ] ; then
    gpg_ids="[]"
  else
    gpg_ids="[$(xargs < "${SCRIPT_DIR}/../../.gpg-id" | tr ' ' ',')]"
  fi

  download_git_id_rsa
  get_git_concourse_pool_clone_full_url_ssh
  get_datadog_secrets
  get_compose_secrets
  get_aiven_secrets
  get_google_oauth_secrets
  get_notify_secrets

  if [ "${ENABLE_DATADOG}" = "true" ] ; then
    # shellcheck disable=SC2154
    if [ -z "${datadog_api_key+x}" ] || [ -z "${datadog_app_key+x}" ] ; then
      echo "Datadog enabled but could not retrieve api or app key. Did you do run \`make ${MAKEFILE_ENV_TARGET} upload-datadog-secrets\`?"
      exit 1
    fi
  fi

  # shellcheck disable=SC2154
  if [ -z "${compose_api_key+x}" ] ; then
    echo "Could not retrieve access token for Compose. Did you run \`make ${MAKEFILE_ENV_TARGET} upload-compose-secrets\`?"
    exit 1
  fi

  # shellcheck disable=SC2154
  if [ -z "${notify_api_key+x}" ] ; then
    echo "Could not retrieve api key for Notify. Did you run \`make ${MAKEFILE_ENV_TARGET} upload-notify-secrets\`?"
    exit 1
  fi

  export EXPOSE_PIPELINE=1
}

generate_vars_file() {
  cat <<EOF
---
pipeline_name: ${pipeline_name}
enable_destroy: ${ENABLE_DESTROY:-}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-true}
aws_account: ${AWS_ACCOUNT:-dev}
makefile_env_target: ${MAKEFILE_ENV_TARGET}
deploy_env: ${DEPLOY_ENV}
state_bucket: ${state_bucket}
test_artifacts_bucket: gds-paas-${DEPLOY_ENV}-test-artifacts
pipeline_trigger_file: ${pipeline_name}.trigger
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION}
debug: ${DEBUG:-}
cf_env_specific_manifest: ${ENV_SPECIFIC_CF_MANIFEST}
INPUT_TAG_PREFIX: ${INPUT_TAG_PREFIX:-}
OUTPUT_TAG_PREFIX: ${OUTPUT_TAG_PREFIX:-}
paas_cf_tag_filter: ${INPUT_TAG_PREFIX:+${INPUT_TAG_PREFIX}[0-9]*.[0-9]*.[0-9]*}
system_dns_zone_name: ${SYSTEM_DNS_ZONE_NAME}
apps_dns_zone_name: ${APPS_DNS_ZONE_NAME}
git_concourse_pool_clone_full_url_ssh: ${git_concourse_pool_clone_full_url_ssh}
ALERT_EMAIL_ADDRESS: ${ALERT_EMAIL_ADDRESS:-}
NEW_ACCOUNT_EMAIL_ADDRESS: "${NEW_ACCOUNT_EMAIL_ADDRESS:-}"
disable_healthcheck_db: ${DISABLE_HEALTHCHECK_DB:-}
test_heavy_load: ${TEST_HEAVY_LOAD:-false}
bosh_az: ${bosh_az}
bosh_manifest_state: bosh-manifest-state-${bosh_az}.json
bosh_fqdn: bosh.${SYSTEM_DNS_ZONE_NAME}
disable_cf_acceptance_tests: ${DISABLE_CF_ACCEPTANCE_TESTS:-}
disable_custom_acceptance_tests: ${DISABLE_CUSTOM_ACCEPTANCE_TESTS:-}
disable_pipeline_locking: ${DISABLE_PIPELINE_LOCKING:-}
datadog_api_key: "${datadog_api_key:-}"
datadog_app_key: "${datadog_app_key:-}"
compose_api_key: ${compose_api_key:-}
compose_billing_email: ${compose_billing_email:-}
compose_billing_password: ${compose_billing_password:-}
aiven_api_token: ${aiven_api_token:-}
enable_datadog: ${ENABLE_DATADOG}
concourse_atc_password: ${CONCOURSE_ATC_PASSWORD}
oauth_client_id: "${oauth_client_id:-}"
oauth_client_secret: "${oauth_client_secret:-}"
notify_api_key: ${notify_api_key:-}
auto_deploy: $([ "${ENABLE_AUTO_DEPLOY:-}" ] && echo "true" || echo "false")
persistent_environment: ${PERSISTENT_ENVIRONMENT}
disable_user_creation: $([ "${NEW_ACCOUNT_EMAIL_ADDRESS:-}" ] && echo "false" || echo "true")
gpg_ids: ${gpg_ids}
EOF
  echo -e "pipeline_lock_git_private_key: |\n  ${git_id_rsa//$'\n'/$'\n'  }"
}

upload_pipeline() {
  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
        "${pipeline_name}" \
        "${SCRIPT_DIR}/../pipelines/${pipeline_name}.yml" \
        <(generate_vars_file)
}

remove_pipeline() {
  ${FLY_CMD} -t "${FLY_TARGET}" destroy-pipeline --pipeline "${pipeline_name}" --non-interactive || true
}

update_pipeline() {
  pipeline_name=$1

  case $pipeline_name in
    create-cloudfoundry)
      upload_pipeline
      "${SCRIPT_DIR}/set_pipeline_ordering.rb" "${pipeline_name}"
      echo "ordered '${pipeline_name}' pipeline first"
    ;;
    deployment-kick-off)
      if [ "${ENABLE_MORNING_DEPLOYMENT:-}" = "true" ]; then
        upload_pipeline
      else
        remove_pipeline
      fi
    ;;
    destroy-*)
      if [ "${ENABLE_DESTROY:-}" = "true" ]; then
        upload_pipeline
      else
        remove_pipeline
      fi
    ;;
    autodelete-cloudfoundry)
      if [ "${ENABLE_AUTODELETE:-}" = "true" ]; then
        upload_pipeline

        echo
        echo "WARNING: Pipeline to autodelete Cloud Foundry has been setup and enabled."
        echo "         To disable it, unset ENABLE_AUTODELETE or pause the pipeline."
      else
        remove_pipeline

        echo
        echo "WARNING: Pipeline to autodelete Cloud Foundry has NOT been setup"
        echo "         To enable it, set ENABLE_AUTODELETE=true"
      fi
    ;;
    *)
      echo "ERROR: Unknown pipeline definition: $pipeline_name"
      exit 1
    ;;
  esac
}

prepare_environment

pipeline_name="test"
generate_vars_file > /dev/null # Check for missing vars
pipeline_name=

for p in $pipelines_to_update; do
  update_pipeline "$p"
done
