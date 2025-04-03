#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

download_git_id_rsa() {
  git_id_rsa_file=$(mktemp -t id_rsa.XXXXXX)

  aws s3 cp "s3://${state_bucket}/git_id_rsa" "${git_id_rsa_file}"

  git_id_rsa=$(cat "${git_id_rsa_file}")

  rm -f "${git_id_rsa_file}"
}

get_git_concourse_pool_clone_full_url_ssh() {
  tfstate_file=$(mktemp -t tfstate.XXXXXX)

  aws s3 cp "s3://${state_bucket}/concourse.tfstate" "${tfstate_file}"

  terraform_state_version=$(ruby < "${tfstate_file}" -rjson -e \
    'puts JSON.load(STDIN)["version"]'
  )

  if [ "${terraform_state_version}" == "4" ]
  then
    git_concourse_pool_clone_full_url_ssh=$(ruby < "${tfstate_file}" -rjson -e \
      'puts JSON.load(STDIN)["outputs"]["git_concourse_pool_clone_full_url_ssh"]["value"]'
    )
  else
    git_concourse_pool_clone_full_url_ssh=$(ruby < "${tfstate_file}" -rjson -e \
      'puts JSON.load(STDIN)["modules"][0]["outputs"]["git_concourse_pool_clone_full_url_ssh"]["value"]'
    )
  fi

  rm -f "${tfstate_file}"
}

prepare_environment() {
  "${SCRIPT_DIR}/fly_sync_and_login.sh"

  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

  pipelines_to_update="${PIPELINES_TO_UPDATE:-create-cloudfoundry deployment-kick-off destroy-cloudfoundry autodelete-cloudfoundry test-certificate-rotation fast-startup-and-shutdown-cf-env}"
  bosh_az=${BOSH_AZ:-${AWS_DEFAULT_REGION}a}

  state_bucket=gds-paas-${DEPLOY_ENV}-state

  download_git_id_rsa
  get_git_concourse_pool_clone_full_url_ssh

  if [ -n "${SLIM_DEV_DEPLOYMENT:-}" ] && [ "${MAKEFILE_ENV_TARGET}" != "dev" ]; then
    echo "SLIM_DEV_DEPLOYMENT set for non-dev deployment. Aborting!"
    exit 1
  fi

  export EXPOSE_PIPELINE=1
}

deploy_env_tag_prefix="*" # this matches all tags and is the default
if [ "${DEPLOY_ENV}" = "prod" ] || [ "${DEPLOY_ENV}" = "prod-lon" ] ; then
  deploy_env_tag_prefix="stg-lon-*" # this matches all tags created by stg-lon
elif [ "${DEPLOY_ENV}" = "stg-lon" ]; then
  deploy_env_tag_prefix="v[0-9]*" # this matches all tags created by release ci
fi

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
branch_name: ${BRANCH:-main}
aws_region: ${AWS_DEFAULT_REGION}
debug: ${DEBUG:-}
env_specific_bosh_vars_file: ${ENV_SPECIFIC_BOSH_VARS_FILE}
env_specific_isolation_segments_dir: ${ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR}
INPUT_TAG_PREFIX: ${INPUT_TAG_PREFIX:-}
OUTPUT_TAG_PREFIX: ${OUTPUT_TAG_PREFIX:-}
paas_cf_tag_filter: ${INPUT_TAG_PREFIX:+${INPUT_TAG_PREFIX}[0-9]*.[0-9]*.[0-9]*}
system_dns_zone_name: ${SYSTEM_DNS_ZONE_NAME}
apps_dns_zone_name: ${APPS_DNS_ZONE_NAME}
apps_hosted_zone_name: ${APPS_HOSTED_ZONE_NAME}
git_concourse_pool_clone_full_url_ssh: ${git_concourse_pool_clone_full_url_ssh}
ALERT_EMAIL_ADDRESS: ${ALERT_EMAIL_ADDRESS:-}
ENABLE_ALERT_NOTIFICATIONS: ${ENABLE_ALERT_NOTIFICATIONS:-true}
NEW_ACCOUNT_EMAIL_ADDRESS: "${NEW_ACCOUNT_EMAIL_ADDRESS:-}"
disable_healthcheck_db: ${DISABLE_HEALTHCHECK_DB:-}
test_heavy_load: ${TEST_HEAVY_LOAD:-false}
bosh_az: ${bosh_az}
bosh_manifest_state: bosh-manifest-state-${bosh_az}.json
bosh_fqdn: bosh.${SYSTEM_DNS_ZONE_NAME}
disable_cf_acceptance_tests: ${DISABLE_CF_ACCEPTANCE_TESTS:-}
disable_app_autoscaler_acceptance_tests: ${DISABLE_APP_AUTOSCALER_ACCEPTANCE_TESTS:-${DISABLE_CF_ACCEPTANCE_TESTS:-}}
disable_custom_acceptance_tests: ${DISABLE_CUSTOM_ACCEPTANCE_TESTS:-}
disable_pipeline_locking: ${DISABLE_PIPELINE_LOCKING:-}
auto_deploy: $([ "${ENABLE_AUTO_DEPLOY:-}" ] && echo "true" || echo "false")
persistent_environment: ${PERSISTENT_ENVIRONMENT}
slim_dev_deployment: ${SLIM_DEV_DEPLOYMENT:-}
monitored_state_bucket: ${MONITORED_STATE_BUCKET:-}
monitored_aws_region: ${MONITORED_AWS_REGION:-}
monitored_deploy_env: ${MONITORED_DEPLOY_ENV:-}
deploy_env_tag_prefix: "${deploy_env_tag_prefix}"
skip_autodelete_await: "${SKIP_AUTODELETE_AWAIT:-false}"
ca_rotation_expiry_days: "${CA_ROTATION_EXPIRY_DAYS}"
enable_paas_admin_continuous_deploy: ${ENABLE_PAAS_ADMIN_CONTINUOUS_DEPLOY:-true}
paas_admin_instance_count: ${PAAS_ADMIN_INSTANCE_COUNT:-6}
disabled_azs: ${DISABLED_AZS:-}
enable_az_healthcheck: ${ENABLE_AZ_HEALTHCHECK:-}
EOF
  echo -e "pipeline_lock_git_private_key: |\\n  ${git_id_rsa//$'\n'/$'\n'  }"
}
#
#upload_pipeline() {
#  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
#        "${pipeline_name}" \
#        "${SCRIPT_DIR}/../pipelines/${pipeline_name}.yml" \
#        <(generate_vars_file)
#}
#
#remove_pipeline() {
#  ${FLY_CMD} -t "${FLY_TARGET}" destroy-pipeline --pipeline "${pipeline_name}" --non-interactive || true
#}
#
#update_pipeline() {
#  pipeline_name=$1
#
#  case $pipeline_name in
#    create-cloudfoundry)
#      upload_pipeline
#      "${SCRIPT_DIR}/set_pipeline_ordering.rb" "${pipeline_name}"
#      echo "ordered '${pipeline_name}' pipeline first"
#    ;;
#    deployment-kick-off)
#      if [ "${ENABLE_MORNING_DEPLOYMENT:-}" = "true" ]; then
#        upload_pipeline
#      else
#        remove_pipeline
#      fi
#    ;;
#    test-*)
#      if [ "${ENABLE_TEST_PIPELINES:-}" = "true" ]; then
#        upload_pipeline
#      else
#        remove_pipeline
#      fi
#    ;;
#    destroy-*)
#      if [ "${ENABLE_DESTROY:-}" = "true" ]; then
#        upload_pipeline
#      else
#        remove_pipeline
#      fi
#    ;;
#    autodelete-cloudfoundry)
#      if [ "${ENABLE_AUTODELETE:-}" = "true" ]; then
#        upload_pipeline
#
#        echo
#        echo "WARNING: Pipeline to autodelete Cloud Foundry has been setup and enabled."
#        echo "         To disable it, unset ENABLE_AUTODELETE or pause the pipeline."
#      else
#        remove_pipeline
#
#        echo
#        echo "WARNING: Pipeline to autodelete Cloud Foundry has NOT been setup"
#        echo "         To enable it, set ENABLE_AUTODELETE=true"
#      fi
#    ;;
#    monitor-*)
#      upload_pipeline
#    ;;
#    fast-startup-and-shutdown-cf-env)
#      if [ "${ENABLE_FAST_STARTUP_AND_SHUTDOWN_CF_ENV:-}" = "true" ]; then
#        upload_pipeline
#      else
#        remove_pipeline
#      fi
#    ;;
#    *)
#      echo "ERROR: Unknown pipeline definition: $pipeline_name"
#      exit 1
#    ;;
#  esac
#}

abort_job() {
  ${FLY_CMD} -t "${FLY_TARGET}" abort-build -j create-cloudfoundry/pipeline-lock -b 1064
#  ${FLY_CMD} -t "${FLY_TARGET}" sync
#  ${FLY_CMD} -t "${FLY_TARGET}" builds -j create-cloudfoundry/pipeline-lock
#  ${FLY_CMD} -t "${FLY_TARGET}" check-resource -r create-cloudfoundry/pipeline-lock
#  ${FLY_CMD} -t "${FLY_TARGET}" unpause-pipeline -p create-cloudfoundry
#  ${FLY_CMD} -t "${FLY_TARGET}" check-resource -r create-cloudfoundry/pipeline-lock
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-2f70-4244-8c4a-f0744690b758
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-306b-4332-8480-09a20f0ac5ab
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-3623-4a59-b98b-e1489107d96a
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-3ad4-47c0-a8ae-83d1cd52e48f
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-4aa6-4975-9b18-8b507df852e3
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-6af4-49a0-a9a3-5f42d4082bac
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 6eb83f6a-844b-4589-a739-01a7d4382740
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 8e00bdf5-734e-43c3-8ba6-b7c0ea24ff1e
#  ${FLY_CMD} -t "${FLY_TARGET}" prune-worker -w 8e00bdf5-d7a4-4d62-b9d2-f47915e482d6
  ${FLY_CMD} -t "${FLY_TARGET}" abort-build -b 76669413
#  fly -t prod-lon sync
#  fly -t my-concourse abort-build -j create-cloudfoundry/pipeline-lock -b 1064

}

prepare_environment

pipeline_name="test"
generate_vars_file > /dev/null # Check for missing vars
pipeline_name=

abort_job
#
#for p in $pipelines_to_update; do
#  update_pipeline "$p"
#done
