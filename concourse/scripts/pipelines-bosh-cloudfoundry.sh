#!/bin/bash
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

env="${DEPLOY_ENV}"
pipelines_to_update="${PIPELINES_TO_UPDATE:-create-bosh-cloudfoundry destroy-microbosh destroy-cloudfoundry autodelete-cloudfoundry}"

cf_manifest_dir="${SCRIPT_DIR}/../../manifests/cf-manifest/deployments"
cf_release_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.cf.version "${cf_manifest_dir}/000-base-cf-deployment.yml")
cf_graphite_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.graphite.version "${cf_manifest_dir}/055-graphite.yml")
cf_grafana_version=$("${SCRIPT_DIR}"/val_from_yaml.rb releases.grafana.version "${cf_manifest_dir}/055-graphite.yml")


generate_base_vars_file() {
   cat <<EOF
---
deploy_env: ${env}
branch_name: ${BRANCH:-master}
environment_class: ${ENVIRONMENT_CLASS}
EOF
}

generate_generic_vars_file() {
   cat <<EOF
---
debug: ${DEBUG:-}
pipeline_name: ${pipeline_name}
state_bucket: ${env}-state
pipeline_trigger_file: ${pipeline_name}.trigger
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
cf-release-version: v${cf_release_version}
cf_graphite_version: ${cf_graphite_version}
cf_grafana_version: ${cf_grafana_version}
EOF
}

generate_env_vars_file() {
  case ${ENVIRONMENT_CLASS} in
    dev)
     cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-dev}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-false}
EOF
    ;;
    ci)
     cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-ci}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-true}
EOF
    ;;
    stage)
     cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-stage}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-true}
EOF
    ;;
    prod)
     cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-prod}
self_update_pipeline: ${SELF_UPDATE_PIPELINE:-true}
EOF
    ;;
  esac
}

generate_manifest_file() {
   # This exists because concourse does not support boolean value interpolation by design
   enable_auto_deploy=$([ "${ENABLE_AUTO_DEPLOY:-}" ] && echo "true" || echo "false")
   sed -e "s/{{auto_deploy}}/${enable_auto_deploy}/" \
       < "${SCRIPT_DIR}/../pipelines/${pipeline_name}.yml"
}

update_pipeline() {
  pipeline_name=$1
  generate_base_vars_file > /dev/null # Check for missing vars
  generate_generic_vars_file > /dev/null # Check for missing vars
  generate_env_vars_file > /dev/null # Check for missing vars

  case $pipeline_name in
    create-bosh-cloudfoundry|destroy-microbosh|destroy-cloudfoundry)
      bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
	"${env}" "${pipeline_name}" \
          <(generate_manifest_file) \
	  <(generate_base_vars_file) \
	  <(generate_generic_vars_file) \
	  <(generate_env_vars_file)
    ;;
    autodelete-cloudfoundry)
      if [ ! "${DISABLE_AUTODELETE:-}" ]; then
	bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
	  "${env}" "${pipeline_name}" \
	  "${SCRIPT_DIR}/../pipelines/${pipeline_name}.yml" \
	  <(generate_base_vars_file) \
	  <(generate_generic_vars_file) \
	  <(generate_env_vars_file)

	echo
	echo "WARNING: Pipeline to autodelete Cloud Foundry has been setup and enabled."
	echo "         To disable it, set DISABLE_AUTODELETE=1 or pause the pipeline."
      else
        yes y | ${FLY_CMD} -t "${FLY_TARGET}" destroy-pipeline --pipeline "${pipeline_name}" || true

	echo
	echo "WARNING: Pipeline to autodelete Cloud Foundry has NOT been setup"
      fi
    ;;
  esac
}

for p in $pipelines_to_update; do
  update_pipeline "$p"
done
