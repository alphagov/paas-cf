#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

download_git_id_rsa() {
  git_id_rsa_file=$(mktemp -t id_rsa.XXXXXX)

  aws s3 cp "s3://${env}-state/git_id_rsa" "${git_id_rsa_file}"

  git_id_rsa=$(cat "${git_id_rsa_file}")

  rm -f "${git_id_rsa_file}"
}

get_git_concourse_pool_clone_full_url_ssh() {
  tfstate_file=$(mktemp -t tfstate.XXXXXX)

  aws s3 cp "s3://${env}-state/concourse.tfstate" "${tfstate_file}"

  git_concourse_pool_clone_full_url_ssh=$(awk -F '"' '/git_concourse_pool_clone_full_url_ssh/ {print $4}' "${tfstate_file}")

  rm -f "${tfstate_file}"
}

prepare_environment() {
  "${SCRIPT_DIR}/fly_sync_and_login.sh"

  env="${DEPLOY_ENV}"
  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

  pipelines_to_update="${PIPELINES_TO_UPDATE:-create-bosh-cloudfoundry destroy-cloudfoundry destroy-microbosh autodelete-cloudfoundry failure-testing}"
  bosh_az=${BOSH_AZ:-eu-west-1a}

  cf_manifest_dir="${SCRIPT_DIR}/../../manifests/cf-manifest/deployments"
  cf_release_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.cf.version "${cf_manifest_dir}/000-base-cf-deployment.yml")
  cf_paas_haproxy_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.paas-haproxy.version "${cf_manifest_dir}/000-base-cf-deployment.yml")
  cf_graphite_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.graphite.version "${cf_manifest_dir}/055-graphite.yml")
  cf_grafana_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.grafana.version "${cf_manifest_dir}/055-graphite.yml")
  cf_aws_broker_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.aws-broker.version "${cf_manifest_dir}/060-aws-broker.yml")

  if [ -z "${SKIP_COMMIT_VERIFICATION:-}" ] ; then
    gpg_ids="[$(xargs < "${SCRIPT_DIR}/../../.gpg-id" | tr ' ' ',')]"
  else
    gpg_ids="[]"
  fi

  download_git_id_rsa
  get_git_concourse_pool_clone_full_url_ssh
}

generate_vars_file() {
  cat <<EOF
---
pipeline_name: ${pipeline_name}
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
cf_grafana_version: ${cf_grafana_version}
cf_aws_broker_version: ${cf_aws_broker_version}
cf_env_specific_manifest: ${ENV_SPECIFIC_CF_MANIFEST}
paas_cf_tag_filter: ${PAAS_CF_TAG_FILTER:-}
TAG_PREFIX: ${TAG_PREFIX:-}
system_dns_zone_name: ${SYSTEM_DNS_ZONE_NAME}
apps_dns_zone_name: ${APPS_DNS_ZONE_NAME}
git_concourse_pool_clone_full_url_ssh: ${git_concourse_pool_clone_full_url_ssh}
ALERT_EMAIL_ADDRESS: ${ALERT_EMAIL_ADDRESS:-}
bosh_az: ${bosh_az}
bosh_manifest_state: bosh-manifest-state-${bosh_az}.json
bosh_fqdn: bosh.${SYSTEM_DNS_ZONE_NAME}
EOF
  echo -e "pipeline_lock_git_private_key: |\n  ${git_id_rsa//$'\n'/$'\n'  }"
}

generate_manifest_file() {
  # This exists because concourse does not support boolean value interpolation by design
  enable_auto_deploy=$([ "${ENABLE_AUTO_DEPLOY:-}" ] && echo "true" || echo "false")
  continuous_smoke_tests_trigger=$([ "${ALERT_EMAIL_ADDRESS:-}" ] && echo "true" || echo "false")
  disable_user_creation=$([ "${DISABLE_USER_CREATION:-}" ] && echo "true" || echo "false")
  sed -e "s/{{auto_deploy}}/${enable_auto_deploy}/" \
      -e "s/{{continuous_smoke_tests_trigger}}/${continuous_smoke_tests_trigger}/" \
      -e "s/{{gpg_ids}}/${gpg_ids}/" \
      -e "s/{{disable_user_creation}}/${disable_user_creation}/" \
    < "${SCRIPT_DIR}/../pipelines/${pipeline_name}.yml"
}

update_pipeline() {
  pipeline_name=$1

  case $pipeline_name in
    create-bosh-cloudfoundry|destroy-microbosh|destroy-cloudfoundry|failure-testing)
      bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
        "${env}" "${pipeline_name}" \
        <(generate_manifest_file) \
        <(generate_vars_file)
    ;;
    autodelete-cloudfoundry)
      if [ -n "${ENABLE_AUTODELETE:-}" ]; then
        bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
          "${env}" "${pipeline_name}" \
          <(generate_manifest_file) \
          <(generate_vars_file)

        echo
        echo "WARNING: Pipeline to autodelete Cloud Foundry has been setup and enabled."
        echo "         To disable it, unset ENABLE_AUTODELETE or pause the pipeline."
      else
        yes y | ${FLY_CMD} -t "${FLY_TARGET}" destroy-pipeline --pipeline "${pipeline_name}" || true

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
