#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)

env=${DEPLOY_ENV-$1}
pipeline="deploy-cloudfoundry"
pipeline_autodelete="autodelete-cloudfoundry"
config="${SCRIPT_DIR}/../pipelines/deploy-cloudfoundry.yml"
config_autodelete="${SCRIPT_DIR}/../pipelines/autodelete-cloudfoundry.yml"

bosh_password=$("$SCRIPT_DIR"/s3get.sh ${env}-state bosh-secrets.yml > /dev/null && awk '$1~/bosh_admin_password/ {print $2}' bosh-secrets.yml)
[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
deploy_env: ${env}
state_bucket: ${env}-state
pipeline_name: ${pipeline}
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
bosh_password: ${bosh_password}
stemcell-version: ${STEMCELL_VERSION:-3104}
cf-release-version: ${CF_RELEASE_VERSION:-225}
nginx-release-version: ${NIGNX_RELEASE_VERSION:-2}
diego-release-version: ${DIEGO_RELEASE_VERSION:-0.1441.0}
garden-release-version: ${GARDEN_RELEASE_VERSION:-0.327.0}
etcd-release-version: ${ETCD_RELEASE_VERSION:-18}
debug: ${DEBUG:-}
EOF
}
generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)

fly -t "$FLY_TARGET" unpause-pipeline --pipeline "${pipeline}"

if [ ! "${DISABLE_AUTODELETE:-}" ]; then
   bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
	  "${env}" "${pipeline_autodelete}" "${config_autodelete}" <(generate_vars_file)

   fly -t "$FLY_TARGET" unpause-pipeline --pipeline "${pipeline_autodelete}"

   echo
   echo "WARNING: Pipeline to autodelete Cloud Foundry has been setup and enabled."
   echo "         To disable it, set DISABLE_AUTODELETE=1 or pause the pipeline."
else
   yes y | fly -t "$FLY_TARGET" destroy-pipeline --pipeline "${pipeline_autodelete}" || true

   echo
   echo "WARNING: Pipeline to autodelete Cloud Foundry has NOT been setup"
fi
