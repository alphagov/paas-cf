#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
FLY_TARGET=${FLY_TARGET:-$ATC_URL}

env=${DEPLOY_ENV-$1}
pipeline="create-deployer"
config="${SCRIPT_DIR}/../pipelines/create-deployer.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100

generate_vars_file() {
   set -u # Treat unset variables as an error when substituting
   cat <<EOF
---
deploy_env: ${env}
tfstate_bucket: bucket=${env}-state
state_bucket: ${env}-state
branch_name: ${BRANCH:-master}
aws_region: ${AWS_DEFAULT_REGION:-eu-west-1}
aws_access_key_id: ${AWS_ACCESS_KEY_ID}
aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY}
concourse_db_password: ${CONCOURSE_DB_PASSWORD}
concourse_atc_password: ${CONCOURSE_ATC_PASSWORD}
log_level: ${LOG_LEVEL:-}
private_ssh_key: |
$(cat ~/.ssh/insecure-deployer | sed 's/^/  /')
EOF
}

generate_vars_file > /dev/null # Check for missing vars

bash "${SCRIPT_DIR}/deploy-pipeline.sh" \
   "${env}" "${pipeline}" "${config}" <(generate_vars_file)

fly -t "${FLY_TARGET}" unpause-pipeline --pipeline "${pipeline}"

# Start pipeline
# curl "${ATC_URL}/pipelines/${pipeline}/jobs/init-bucket/builds" -X POST

cat <<EOF
You can watch the last vpc deploy job by running the command below.
You might need to wait a few moments before the latest build starts.

fly -t "${FLY_TARGET}" watch -j "${pipeline}/vpc"
EOF
