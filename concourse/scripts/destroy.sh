#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0) && pwd)

env=${DEPLOY_ENV-$1}
pipeline="destroy-cf"
config="${SCRIPT_DIR}/../pipelines/destroy.yml"

[[ -z "${env}" ]] && echo "Must provide environment name" && exit 100
bash "${SCRIPT_DIR}/deploy-pipeline.sh" "${env}" "${pipeline}" "${config}"

echo "Pipeline updated, about to trigger destroy..."
if [[ -z "${SKIP_CONFIRM}" ]] ; then
   read -sn 1 -p "This is a destructive operation, are you sure you want to do this [Y/N]? "; [[ $${REPLY:0:1} = [Yy] ]];
fi

export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
export fly_target=${FLY_TARGET:-tutorial}

fly unpause-pipeline --pipeline "${pipeline}"
curl "${ATC_URL}/pipelines/${pipeline}/jobs/destroy-vpc/builds" -X POST
fly -t "${fly_target}" watch -j "${pipeline}/destroy-vpc"

