#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0) && pwd)

env=${DEPLOY_ENV-$1}
pipeline="cf-deploy"
config="${SCRIPT_DIR}/../pipelines/deploy.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100
bash "${SCRIPT_DIR}/deploy-pipeline.sh" "${env}" "${pipeline}" "${config}"


export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
export fly_target=${FLY_TARGET:-tutorial}

fly unpause-pipeline --pipeline "${pipeline}"
curl "${ATC_URL}/pipelines/${pipeline}/jobs/init-bucket/builds" -X POST
fly -t "${fly_target}" watch -j "${pipeline}/vpc"

