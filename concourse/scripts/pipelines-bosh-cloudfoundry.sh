#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

# shellcheck disable=SC1090
. "${SCRIPT_DIR}/lib/datadog.sh"

download_git_id_rsa() {
  git_id_rsa_file=$(mktemp -t id_rsa.XXXXXX)

  aws s3 cp "s3://${env}-state/git_id_rsa" "${git_id_rsa_file}"

  git_id_rsa=$(cat "${git_id_rsa_file}")

  rm -f "${git_id_rsa_file}"
}

get_git_concourse_pool_clone_full_url_ssh() {
  tfstate_file=$(mktemp -t tfstate.XXXXXX)

  aws s3 cp "s3://${env}-state/concourse.tfstate" "${tfstate_file}"

  git_concourse_pool_clone_full_url_ssh=$(ruby < "${tfstate_file}" -rjson -e \
    'puts JSON.load(STDIN)["modules"][0]["outputs"]["git_concourse_pool_clone_full_url_ssh"]["value"]'
  )

  rm -f "${tfstate_file}"
}

prepare_environment() {
  "${SCRIPT_DIR}/fly_sync_and_login.sh"

  env="${DEPLOY_ENV}"
  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

  pipelines_to_update="${PIPELINES_TO_UPDATE:-create-bosh-cloudfoundry destroy-cloudfoundry destroy-microbosh autodelete-cloudfoundry failure-testing}"
  bosh_az=${BOSH_AZ:-eu-west-1a}

  cf_manifest_dir="${SCRIPT_DIR}/../../manifests/cf-manifest/manifest"
  cf_release_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.cf.version "${cf_manifest_dir}/000-base-cf-deployment.yml")
  cf_paas_haproxy_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.paas-haproxy.version "${cf_manifest_dir}/000-base-cf-deployment.yml")
  cf_graphite_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.graphite.version "${cf_manifest_dir}/040-graphite.yml")
  cf_aws_broker_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.aws-broker.version "${cf_manifest_dir}/050-rds-broker.yml")
  cf_os_conf_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.os-conf.version "${cf_manifest_dir}/../runtime-config/runtime-config-base.yml")
  cf_logsearch_for_cloudfoundry_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.logsearch-for-cloudfoundry.version "${cf_manifest_dir}/800-logsearch.yml")
  cf_datadog_for_cloudfoundry_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.datadog-for-cloudfoundry.version "${cf_manifest_dir}/000-base-cf-deployment.yml")

  if [ "${SKIP_COMMIT_VERIFICATION:-}" = "true" ] ; then
    gpg_ids="[]"
  else
    gpg_ids="[$(xargs < "${SCRIPT_DIR}/../../.gpg-id" | tr ' ' ',')]"
  fi

  download_git_id_rsa
  get_git_concourse_pool_clone_full_url_ssh
  get_datadog_secrets

  export EXPOSE_PIPELINE=1
}

generate_vars_file() {
  cat <<EOF
---
pipeline_name: ${pipeline_name}
enable_destroy: ${ENABLE_DESTROY:-}
makefile_env_target: ${MAKEFILE_ENV_TARGET:-dev}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-true}
skip_upload_generated_certs: ${SKIP_UPLOAD_GENERATED_CERTS:-false}
aws_account: ${AWS_ACCOUNT:-dev}
deploy_env: ${env}
state_bucket: ${env}-state
pipeline_trigger_file: ${pipeline_name}.trigger
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION}
debug: ${DEBUG:-}
cf-release-version: v${cf_release_version}
cf-paas-haproxy-release-version: ${cf_paas_haproxy_version}
cf_graphite_version: ${cf_graphite_version}
cf_aws_broker_version: ${cf_aws_broker_version}
cf_datadog_for_cloudfoundry_version: ${cf_datadog_for_cloudfoundry_version}
cf_os_conf_version: ${cf_os_conf_version}
cf_logsearch_for_cloudfoundry_version: ${cf_logsearch_for_cloudfoundry_version}
cf_env_specific_manifest: ${ENV_SPECIFIC_CF_MANIFEST}
paas_cf_tag_filter: ${PAAS_CF_TAG_FILTER:-}
TAG_PREFIX: ${TAG_PREFIX:-}
system_dns_zone_name: ${SYSTEM_DNS_ZONE_NAME}
apps_dns_zone_name: ${APPS_DNS_ZONE_NAME}
git_concourse_pool_clone_full_url_ssh: ${git_concourse_pool_clone_full_url_ssh}
ALERT_EMAIL_ADDRESS: ${ALERT_EMAIL_ADDRESS:-}
NEW_ACCOUNT_EMAIL_ADDRESS: ${NEW_ACCOUNT_EMAIL_ADDRESS:-}
disable_healthcheck_db: ${DISABLE_HEALTHCHECK_DB:-}
bosh_az: ${bosh_az}
bosh_manifest_state: bosh-manifest-state-${bosh_az}.json
bosh_fqdn: bosh.${SYSTEM_DNS_ZONE_NAME}
disable_cf_acceptance_tests: ${DISABLE_CF_ACCEPTANCE_TESTS:-}
disable_custom_acceptance_tests: ${DISABLE_CUSTOM_ACCEPTANCE_TESTS:-}
disable_pipeline_locking: ${DISABLE_PIPELINE_LOCKING:-}
datadog_api_key: ${datadog_api_key:-}
datadog_app_key: ${datadog_app_key:-}
enable_datadog: ${ENABLE_DATADOG}
enable_cve_notifier: ${ENABLE_CVE_NOTIFIER:-false}
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
        "${env}" "${pipeline_name}" \
        <(generate_manifest_file) \
        <(generate_vars_file)
}

remove_pipeline() {
  yes y | ${FLY_CMD} -t "${FLY_TARGET}" destroy-pipeline --pipeline "${pipeline_name}" || true
}

update_pipeline() {
  pipeline_name=$1

  case $pipeline_name in
    create-bosh-cloudfoundry)
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
