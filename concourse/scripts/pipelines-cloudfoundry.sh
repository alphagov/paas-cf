#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

env=${DEPLOY_ENV-$1}
pipeline_autodelete="autodelete-cloudfoundry"
config_autodelete="${SCRIPT_DIR}/../pipelines/autodelete-cloudfoundry.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
aws_account: ${AWS_ACCOUNT:-dev}
deploy_env: ${env}
state_bucket: ${env}-state
pipeline_trigger_file: ${trigger_file}
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
stemcell-version: ${STEMCELL_VERSION:-3104}
debug: ${DEBUG:-}
EOF
}


for ACTION in deploy destroy; do
  trigger_file="${ACTION}-cloudfoundry.trigger"
  generate_vars_file > /dev/null # Check for missing vars

  bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
    "${env}" "${ACTION}-cloudfoundry" \
    "${SCRIPT_DIR}/../pipelines/${ACTION}-cloudfoundry.yml" \
    <(generate_vars_file)
done

if [ ! "${DISABLE_AUTODELETE:-}" ]; then
   trigger_file="autodelete-cloudfoundry.trigger"
   bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
	  "${env}" "${pipeline_autodelete}" "${config_autodelete}" <(generate_vars_file)

   echo
   echo "WARNING: Pipeline to autodelete Cloud Foundry has been setup and enabled."
   echo "         To disable it, set DISABLE_AUTODELETE=1 or pause the pipeline."
else
   yes y | ${FLY_CMD:-fly} -t "${FLY_TARGET:-$env}" destroy-pipeline --pipeline "${pipeline_autodelete}" || true

   echo
   echo "WARNING: Pipeline to autodelete Cloud Foundry has NOT been setup"
fi
