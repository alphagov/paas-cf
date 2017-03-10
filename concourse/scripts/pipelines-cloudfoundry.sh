#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/datadog.sh"

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/google-oauth.sh"

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

get_tracker_token() {
  secrets_uri="s3://${state_bucket}/tracker_token"
  export tracker_token
  if aws s3 ls "${secrets_uri}" > /dev/null ; then
    tracker_token=$(aws s3 cp "${secrets_uri}" -)
  fi
}

prepare_environment() {
  "${SCRIPT_DIR}/fly_sync_and_login.sh"

  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

  pipelines_to_update="${PIPELINES_TO_UPDATE:-create-cloudfoundry destroy-cloudfoundry autodelete-cloudfoundry failure-testing}"
  bosh_az=${BOSH_AZ:-eu-west-1a}

  state_bucket=gds-paas-${DEPLOY_ENV}-state

  cf_manifest_dir="${SCRIPT_DIR}/../../manifests/cf-manifest/manifest"
  cf_release_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.cf.version "${cf_manifest_dir}/000-base-cf-deployment.yml")
  cf_graphite_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.graphite.version "${cf_manifest_dir}/040-graphite.yml")

  if [ "${SKIP_COMMIT_VERIFICATION:-}" = "true" ] ; then
    gpg_ids="[]"
  else
    gpg_ids="[$(xargs < "${SCRIPT_DIR}/../../.gpg-id" | tr ' ' ',')]"
  fi

  download_git_id_rsa
  get_git_concourse_pool_clone_full_url_ssh
  get_datadog_secrets
  get_google_oauth_secrets

  if [ "${ENABLE_DATADOG}" = "true" ] ; then
    # shellcheck disable=SC2154
    if [ -z "${datadog_api_key+x}" ] || [ -z "${datadog_app_key+x}" ] ; then
      echo "Datadog enabled but could not retrieve api or app key. Did you do run \`make dev upload-datadog-secrets\`?"
      exit 1
    fi
  fi

  export EXPOSE_PIPELINE=1

  get_tracker_token
  if [ "${DEPLOY_RUBBERNECKER:-false}" = "true" ] ; then
    if [ -z "${tracker_token+x}" ] ; then
      echo "Rubbernecker deployment enabled but could not retrieve the API token. Did you run \`make <env> upload-tracker-token\`?"
      exit 1
    fi
  fi

}

generate_vars_file() {
  cat <<EOF
---
pipeline_name: ${pipeline_name}
enable_destroy: ${ENABLE_DESTROY:-}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-true}
skip_upload_generated_certs: ${SKIP_UPLOAD_GENERATED_CERTS:-false}
aws_account: ${AWS_ACCOUNT:-dev}
deploy_env: ${DEPLOY_ENV}
state_bucket: ${state_bucket}
test_artifacts_bucket: gds-paas-${DEPLOY_ENV}-test-artifacts
pipeline_trigger_file: ${pipeline_name}.trigger
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION}
debug: ${DEBUG:-}
cf_release_version: v${cf_release_version}
cf_graphite_version: ${cf_graphite_version}
cf_env_specific_manifest: ${ENV_SPECIFIC_CF_MANIFEST}
paas_cf_tag_filter: ${PAAS_CF_TAG_FILTER:-}
TAG_PREFIX: ${TAG_PREFIX:-}
system_dns_zone_name: ${SYSTEM_DNS_ZONE_NAME}
apps_dns_zone_name: ${APPS_DNS_ZONE_NAME}
git_concourse_pool_clone_full_url_ssh: ${git_concourse_pool_clone_full_url_ssh}
ALERT_EMAIL_ADDRESS: ${ALERT_EMAIL_ADDRESS:-}
NEW_ACCOUNT_EMAIL_ADDRESS: ${NEW_ACCOUNT_EMAIL_ADDRESS:-}
disable_healthcheck_db: ${DISABLE_HEALTHCHECK_DB:-}
test_heavy_load: ${TEST_HEAVY_LOAD:-false}
bosh_az: ${bosh_az}
bosh_manifest_state: bosh-manifest-state-${bosh_az}.json
bosh_fqdn: bosh.${SYSTEM_DNS_ZONE_NAME}
disable_cf_acceptance_tests: ${DISABLE_CF_ACCEPTANCE_TESTS:-}
disable_custom_acceptance_tests: ${DISABLE_CUSTOM_ACCEPTANCE_TESTS:-}
disable_pipeline_locking: ${DISABLE_PIPELINE_LOCKING:-}
datadog_api_key: ${datadog_api_key:-}
datadog_app_key: ${datadog_app_key:-}
enable_datadog: ${ENABLE_DATADOG}
enable_paas_dashboard: ${ENABLE_PAAS_DASHBOARD:-false}
deploy_rubbernecker: ${DEPLOY_RUBBERNECKER:-false}
tracker_token: ${tracker_token:-}
pivotal_project_id: ${PIVOTAL_PROJECT_ID:-1275640}
concourse_atc_password: ${CONCOURSE_ATC_PASSWORD}
oauth_client_id: ${oauth_client_id:-}
oauth_client_secret: ${oauth_client_secret:-}
EOF
  echo -e "pipeline_lock_git_private_key: |\n  ${git_id_rsa//$'\n'/$'\n'  }"
}

generate_manifest_file() {
  # This exists because concourse does not support boolean value interpolation by design
  enable_auto_deploy=$([ "${ENABLE_AUTO_DEPLOY:-}" ] && echo "true" || echo "false")
  continuous_smoke_tests_trigger=$([ "${ALERT_EMAIL_ADDRESS:-}" ] && echo "true" || echo "false")
  disable_user_creation=$([ "${NEW_ACCOUNT_EMAIL_ADDRESS:-}" ] && echo "false" || echo "true")
  sed -e "s/{{auto_deploy}}/${enable_auto_deploy}/" \
      -e "s/{{continuous_smoke_tests_trigger}}/${continuous_smoke_tests_trigger}/" \
      -e "s/{{gpg_ids}}/${gpg_ids}/" \
      -e "s/{{disable_user_creation}}/${disable_user_creation}/" \
    < "${SCRIPT_DIR}/../pipelines/${pipeline_name}.yml"
}

upload_pipeline() {
  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
        "${pipeline_name}" \
        <(generate_manifest_file) \
        <(generate_vars_file)
}

remove_pipeline() {
  yes y | ${FLY_CMD} -t "${FLY_TARGET}" destroy-pipeline --pipeline "${pipeline_name}" || true
}

update_pipeline() {
  pipeline_name=$1

  case $pipeline_name in
    create-cloudfoundry)
      upload_pipeline
    ;;
    failure-testing)
      if [ "${ENABLE_FAILURE_TESTING:-}" = "true" ]; then
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
