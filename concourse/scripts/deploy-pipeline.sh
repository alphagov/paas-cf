#!/bin/bash

env=${DEPLOY_ENV:-$1}
pipeline=${PIPELINE:-$2}
config=${PIPELINE_CONFIG:-$3}
[[ -z "${env}" ]]      && echo "Must provide environment name"     && exit 100
[[ -z "${pipeline}" ]] && echo "Must provide pipeline name"        && exit 101
[[ -z "${config}" ]]   && echo "Must provide pipeline config file" && exit 101

branch_name=${BRANCH:-master}
aws_region=${AWS_DEFAULT_REGION:-eu-west-1}

export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
export fly_target=${FLY_TARGET:-tutorial}
echo "Concourse API target ${fly_target}"
echo "Concourse API $ATC_URL"
echo "AWS Region ${aws_region}"
echo "Branch ${branch_name}"
echo
echo "Deployment ${env}"
echo "Pipeline ${pipeline}"
echo "Config file ${config}"

yes y | fly -t "${fly_target}" set-pipeline --config "${config}" --pipeline "${pipeline}" \
--var "deploy_env=${env}" \
--var "tfstate_bucket=bucket=${env}-state" \
--var "state_bucket=${env}-state" \
--var "branch_name=${branch_name}" \
--var "aws_region=${aws_region}" \
--var "aws_access_key_id=${AWS_ACCESS_KEY_ID}" \
--var "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}"

