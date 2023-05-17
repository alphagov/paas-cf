#!/usr/bin/env bash

# This script can be used in isolation, or as part of a concourse pipeline
# to action fast startups and shutdowns of cf dev envs. All ec2 and rds 
# instances tagged with the targetted env or created via the relevant rds
# broker of that env are shutdown, except for those relating to bosh and
# concourse to allow the env to start up again. The bosh resurrector is
# disabled to prevent bosh from trying to re-create the instances.
# To use the script locally, you must first log in to the relevant bosh and
# have the other pre-reqs installed.

set -e -u -o pipefail
shopt -s inherit_errexit

skip_bosh='no'

main() {
  parse_args "$@"
  print_header
  check_dependencies
  validate_initial_state
  if [[ "${action}" = "start" ]]; then
    manage_db_instances_state
    manage_ec2_instances_state
    toggle_bosh_resurrector "on"
    run_health_checks
  fi
  if [[ "${action}" = "stop" ]]; then
    toggle_bosh_resurrector "off"
    manage_ec2_instances_state
    manage_db_instances_state
  fi
  echo "${env_arg} is now ${past_tense}"
  update_usage_and_slack
  echo "done."
  echo
}

# action ec2 instances state change, loop waiting for target state
manage_ec2_instances_state() {
  local initial_ec2_instances
  initial_ec2_instances=$(get_ec2_instances "${initial_ec2_state}")
  local initial_ec2_instances_ids
  initial_ec2_instances_ids=$(get_ec2_instances_ids "${initial_ec2_instances}")
  local initial_ec2_instances_count
  initial_ec2_instances_count=$(get_length "${initial_ec2_instances_ids}")
  if [[ "${initial_ec2_instances_count}" = '0' || "${initial_ec2_instances_count}" = '' ]]; then
    echo "${env_arg} ec2 instances are already ${past_tense}"
    return 0
  fi
  echo "found ${initial_ec2_instances_count} ec2 instances to ${action}..."
  trigger_ec2_instances_state_update "${initial_ec2_instances_ids}" "${action}"
  echo "issued ec2 instances state change: ${initial_ec2_state}->${target_ec2_state}..."
  local target_ec2_instances_count='0'
  local previous_ec2_instances_count=''
  while [[ ${target_ec2_instances_count} -lt ${initial_ec2_instances_count} ]]; do
    local target_ec2_instances
    target_ec2_instances=$(get_ec2_instances "${target_ec2_state}" "${initial_ec2_instances_ids}")
    local target_ec2_instances_ids
    target_ec2_instances_ids=$(get_ec2_instances_ids "${target_ec2_instances}")
    local target_ec2_instances_count
    target_ec2_instances_count=$(get_length "${target_ec2_instances_ids}")
    if [[ ${previous_ec2_instances_count} -ne ${target_ec2_instances_count} ]] || [[ "${previous_ec2_instances_count}" = '' ]]; then
      echo "ec2 instances ${target_ec2_state}: ${target_ec2_instances_count}/${initial_ec2_instances_count}"
      previous_ec2_instances_count=${target_ec2_instances_count}
      sleep 3
    fi
  done
}

# action db instances state change, loop waiting for target state
manage_db_instances_state() {
  local initial_db_instances
  initial_db_instances=$(get_db_instances "${initial_db_state}")
  local initial_db_instances_ids
  initial_db_instances_ids=$(get_db_instances_ids "${initial_db_instances}")
  local initial_db_instances_count
  initial_db_instances_count=$(get_length "${initial_db_instances_ids}")
  if [[ "${initial_db_instances_count}" = '0' || "${initial_db_instances_count}" = '' ]]; then
    echo "${env_arg} db instances are already ${past_tense}"
    return 0
  fi
  echo "found ${initial_db_instances_count} db instances to ${action}..."
  trigger_db_instances_state_update "${initial_db_instances_ids}" "${action}"
  echo "issued db instances state change: ${initial_db_state}->${target_db_state}..."
  local target_db_instances_count='0'
  local previous_db_instances_count=''
  while [[ ${target_db_instances_count} -lt ${initial_db_instances_count} ]]; do
    local target_db_instances
    target_db_instances=$(get_db_instances "${target_db_state}" "${initial_db_instances_ids}")
    local target_db_instances_ids
    target_db_instances_ids=$(get_db_instances_ids "${target_db_instances}")
    local target_db_instances_count
    target_db_instances_count=$(get_length "${target_db_instances_ids}")
    if [[ ${previous_db_instances_count} -ne ${target_db_instances_count} ]] || [[ "${previous_db_instances_count}" = '' ]]; then
      echo "db instances ${target_db_state}: ${target_db_instances_count}/${initial_db_instances_count}"
      previous_db_instances_count=${target_db_instances_count}
      sleep 3
    fi
  done
}

print_error() {
  local string
  string="${1:-}"
  local level
  level="${2:-FATAL}"
  echo -e "${level}: ${string}" >&2
  if [[ "${level}" = 'FATAL' ]]; then
    echo
    exit 1
  fi
}

check_dependencies() {
  echo 'checking dependencies...'
  local bash_ver
  bash_ver=$(echo "${BASH_VERSION}" | cut -d'.' -f1)
  if [[ "${bash_ver}" -lt 4 ]]; then
    print_error 'requires bash version >= 4'
  fi
  if ! command -v bosh >/dev/null 2>&1; then
    print_error 'missing bosh cli'
  fi
  if ! command -v jq >/dev/null 2>&1; then
    print_error 'missing jq'
  fi
  if ! command -v aws >/dev/null 2>&1; then
    print_error 'missing aws cli'
  fi
}

validate_initial_state() {
  echo 'validating initial state...'
  # possible deployments: ${env_arg} app-autoscaler prometheus concourse
  local deployments="concourse" 
  local deployment
  local deployment_count=0
  for deployment in ${deployments}; do
    if bosh vms -d "${deployment}" >/dev/null 2>&1; then
      ((deployment_count=deployment_count+1))
    fi
  done
  if [[ ${deployment_count} -lt 1 ]]; then
    print_error 'not logged in to bosh, or no relevant bosh deployments exist. skipping all subsequent bosh operations' INFO
    skip_bosh='yes'
  fi
  # make sure we are logged into the correct bosh env
  if [[ "${skip_bosh}" != 'yes' ]] && [[ "${BOSH_ENVIRONMENT:?}" != "bosh.${env_arg}.dev.cloudpipeline.digital" ]]; then
    print_error "wrong bosh env targeted (expecting: ${env_arg})"
  fi
  if ! aws ec2 describe-instances >/dev/null 2>&1; then
    print_error 'not logged in to aws'
  fi
  local ec2_instances
  ec2_instances=$(get_ec2_instances)
  local ec2_instances_ids
  ec2_instances_ids=$(get_ec2_instances_ids "${ec2_instances}")
  local ec2_instances_count
  ec2_instances_count=$(get_length "${ec2_instances_ids}")
  if [[ "${ec2_instances_count}" = '0' || "${ec2_instances_count}" = '' ]]; then
    print_error "env does not exist: ${env_arg}"
  fi
  # check that ec2 instances are not already mid state change
  local ec2_instances_transitioning
  ec2_instances_transitioning=$(get_ec2_instances 'stopping,starting,pending,shutting-down')
  local ec2_instances_transitioning_ids
  ec2_instances_transitioning_ids=$(get_ec2_instances_ids "${ec2_instances_transitioning}")
  local ec2_instances_transitioning_count
  ec2_instances_transitioning_count=$(get_length "${ec2_instances_transitioning_ids}")
  if [[ "${ec2_instances_transitioning_count}" != '0' || "${ec2_instances_transitioning_count}" = '' ]]; then
    print_error "env is already in transition: ${env_arg}"
  fi
}

parse_args() {
  env_arg="${1:-}"
  if [[ "${env_arg}" = '' ]]; then
    print_error 'expecting valid env in arg1 ( eg: dev01 )'
  fi
  if [[ "${env_arg}" = 'prod' ]] || [[ "${env_arg}" = 'prod-lon' ]]; then
    print_error 'exiting due to production saftey check!'
  fi
  action_arg="${2:-}"
  if ! [[ "${action_arg}" = 'sleep' || "${action_arg}" = 'wake' ]]; then
    print_error 'expecting valid action in arg2 ( sleep | wake )'
  fi
  if [[ "${action_arg}" = 'sleep' ]]; then
    action='stop'
    initial_ec2_state='running'
    target_ec2_state='stopped'
    initial_db_state='available'
    target_db_state='stopped'
    past_tense='asleep'
  elif [[ "${action_arg}" = 'wake' ]]; then
    action='start'
    initial_ec2_state='stopped'
    target_ec2_state='running'
    initial_db_state='stopped'
    target_db_state='available'
    past_tense='awake'
  fi
  webhook_arg="${3:-}"
  if [[ "${webhook_arg}" = '' ]]; then
    print_error 'expecting valid slack webhook url in arg3'
  fi
}

print_header() {
  echo '
  ┌─────────────────────────────┐
    Fast Startup and Shutdown CF Env
  └─────────────────────────────┘
  '
  echo "  env: ${env_arg}"
  echo "  action: ${action_arg}"
  echo
}

do_cmd() {
  local cmd="${1:-}"
  local out
  if ! out=$(bash -c "${cmd}"); then
    print_error "could not execute cmd: ${cmd}"
  fi
  echo "${out}"
}

# get ec2 instances for env with optional id list and status filters
get_ec2_instances() {
  local state="${1:-}"
  local ids="${2:-}"
  local cmd="aws ec2 describe-instances --filters Name=tag:deploy_env,Values='${env_arg}'"
  local out
  local instances
  if [[ "${state}" != "" ]]; then
    cmd+=" Name=instance-state-name,Values='${state}'"
  fi
  if [[ "${ids}" != "" ]]; then
    cmd+=" --instance-ids '${ids}'"
    out=$(do_cmd "${cmd}")
    jq_query "${out}" '[.Reservations[].Instances[]]'
  else
    out=$(do_cmd "${cmd}")
    instances=$(jq_query "${out}" '[.Reservations[].Instances[]]')
    local tags_to_exclude='[{"instance_group":"bosh"},{"instance_group":"concourse"},{"instance_group":"concourse-worker"}]'
    get_ec2_instances_excluding_tags "${instances}" "${tags_to_exclude}"
  fi
}

get_ec2_instances_ids() {
  local json="${1:-}"
  jq_query "${json}" '[.[].InstanceId]'
}

get_db_instances_ids() {
  local json="${1:-}"
  jq_query "${json}" '[.[].DBInstanceIdentifier]'
}

get_length() {
  local json="${1:-}"
  jq_query "${json}" '.|length'
}

jq_query() {
  local json="${1:-}"
  local query="${2:-}"
  local options="${3:-}"
  if [[ "${options}" = 'raw' ]]; then
    echo "${json}" | jq -c -r "${query}"
  else
    echo "${json}" | jq -c "${query}"
  fi
}

# exclude specific tags
get_ec2_instances_excluding_tags() {
  local json="${1:-}"
  local tags="${2:-}"
  local key
  local val
  local query
  local keyval
  for keyval in $(jq_query "${tags}" '.[]'); do
    key=$(jq_query "${keyval}" '.|keys[]')
    val=$(jq_query "${keyval}" ".${key}")
    query+="|select(contains({Tags:[{Key:${key}},{Value:${val}}]})|not)"
  done
  jq_query "${json}" "[.[]${query}]"
}

# get db instances for env with optional id list and status filters
get_db_instances() {
  local state="${1:-}"
  local ids="${2:-}"
  local cmd='aws rds describe-db-instances'
  if [[ "${ids}" != "" ]]; then
    cmd+=" --filters Name=db-instance-id,Values='${ids}'"
  fi
  local all_db_instances
  all_db_instances=$(do_cmd "${cmd}")
  local db_instances
  local query="|select(contains({TagList:[{Key:\"Broker Name\"},{Value:\"${env_arg}\"}]}) or contains({TagList:[{Key:\"deploy_env\"},{Value:\"${env_arg}\"}]}))"
  query+="|select(.DBInstanceIdentifier != \"${env_arg}-bosh\")"
  query+="|select(.DBInstanceIdentifier != \"${env_arg}-concourse\")"
  if [[ "${state}" != "" ]]; then
    query+="|select(.DBInstanceStatus == \"${state}\")"
  fi
  db_instances=$(jq_query "${all_db_instances}" "[.DBInstances[]${query}]")
  echo "${db_instances}"
}

# action ec2 instances state change
trigger_ec2_instances_state_update() {
  local instances="${1:-}"
  local action="${2:-}"
  if ! aws ec2 "${action}"-instances --instance-ids "${instances}" </dev/null >/dev/null 2>&1; then
    print_error 'trigger_ec2_instances_state_update failed'
  fi
}

# action db instances state change
trigger_db_instances_state_update() {
  local instances="${1:-}"
  local action="${2:-}"
  local instance
  for instance in $(jq_query "${instances}" '.[]' 'raw'); do
    if ! aws rds "${action}"-db-instance --db-instance-identifier "${instance}" </dev/null >/dev/null 2>&1; then
      print_error 'trigger_db_instances_state_update failed'
    fi
  done
}

# ensure that the cf api and billing apps are responding correctly after a startup
run_health_checks() {
  local retry_count=1
  local max_retries=200
  local http_response_code=""
  echo "running health checks..."  
  while [[ "${http_response_code}" != "200" && ${retry_count} -le ${max_retries} ]]; do
    echo "attempting to connect to cf-api ${retry_count}/${max_retries}"
    sleep 3
    http_response_code=$(curl -o /dev/null -s -w "%{http_code}\n" --max-time 3 https://api."${env_arg}".dev.cloudpipeline.digital || true)
    ((retry_count=retry_count+1))
  done
  if [[ "${http_response_code}" = "200" ]]; then
    echo 'cf-api healthcheck passed'
  else
    print_error 'failed healthchecks'
  fi
  local http_response=''
  retry_count='1'
  local good_response='{"ok":true}'
  while [[ "${http_response}" != "${good_response}" && ${retry_count} -le ${max_retries} ]]; do
    echo "attempting to connect to billing-api ${retry_count}/${max_retries}"
    sleep 3
    http_response=$(curl -s --max-time 3 https://billing."${env_arg}".dev.cloudpipeline.digital | jq -c . 2>/dev/null || true)
    ((retry_count=retry_count+1))
  done
  if [[ "${http_response}" = "${good_response}" ]]; then
    echo 'billing-api healthcheck passed'
  else
    print_error 'failed healthchecks'
  fi
}

# enable/disable bosh resurrector
toggle_bosh_resurrector() {
  local action="${1:-}"
  if [[ ${skip_bosh} = 'yes' ]]; then
    return 0
  fi
  if ! bosh update-resurrection "${action}" >/dev/null 2>&1; then
    print_error "could not execute: bosh update-resurrection ${action}"
  fi
  echo "bosh resurrector toggled ${action}"
}

# update dev env usage and send slack update message
update_usage_and_slack() {
  local usage_msg=""
  echo "updating dev-env-usage..."
  local build_created_by
  build_created_by=$(jq -r '.build_created_by' < build-created-by-keyval/version.json)
  local update_usage="${build_created_by} | ${past_tense}"
  local s3_dev_envs
  s3_dev_envs=$(aws s3api list-buckets | jq -r '.Buckets[].Name|match("gds-paas-(dev[0-9][0-9])-state").captures[].string')
  local s3_dev_env
  for s3_dev_env in ${s3_dev_envs}; do
    local existing_usage
    existing_usage=$(aws s3 cp "s3://gds-paas-${s3_dev_env}-state/dev-env-usage-file" -)
    if [[ "${env_arg}" = "${s3_dev_env}" ]]; then
      if [[ "${existing_usage}" != "${update_usage}" ]]; then
        existing_usage="${update_usage}"
        echo "${existing_usage}" | aws s3 cp - "s3://gds-paas-${s3_dev_env}-state/dev-env-usage-file"
      fi
    fi
    usage_msg="${usage_msg}\n${s3_dev_env} | ${existing_usage}"
  done
  echo -e "dev-env-usage summary${usage_msg}" | sed 's/^/  /'
  curl -s -H 'Content-type: application/json' -d "{\"text\":\"*dev-env-usage summary*\n\`\`\`${usage_msg}\`\`\`\"}" "${webhook_arg}" >/dev/null 2>&1
}

main "$@"
