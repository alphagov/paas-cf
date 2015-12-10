#!/bin/bash
set -e

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

env=${DEPLOY_ENV-$1}
pipeline="cf-deploy"
config="${SCRIPT_DIR}/../pipelines/create-deployer.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100
bash "${SCRIPT_DIR}/deploy-pipeline.sh" "${env}" "${pipeline}" "${config}"


export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
export fly_target=${FLY_TARGET:-tutorial}

fly unpause-pipeline --pipeline "${pipeline}"
curl "${ATC_URL}/pipelines/${pipeline}/jobs/init-bucket/builds" -X POST

cat <<EOF
You can watch the last vpc deploy job by running the command below.
You might need to wait a few moments before the latest build starts.

fly -t "${fly_target}" watch -j "${pipeline}/vpc"
EOF
