#!/usr/bin/env bash

# This script can be used in isolation, or as part of the destroy-cloudfoundry pipeline
# to iterate over the orgs/spaces/apps/bindings in any targeted cloud foundry platform
# and will unbind any bound services before deleting them.
# The admin org, and service-broker space are processed last in order to allow dependant
# services to delete cleanly.
# By default, non-dev platforms are protected from changes unless the relevant argument
# is given at runtime.
# Any error throughout the run will result in the process halting at that stage.

set -e -u -o pipefail
shopt -s inherit_errexit
IFS=$'\n'

#### config for test modes
test_org_count="3"
test_space_count="3"
test_deploy_count="3"
test_prefix="destroy-tests"
test_dir="/tmp/${test_prefix}"

output_table="org|space|service|app|status"
test_orgs=""

usage() {
  echo
  echo "usage: $0 ( test | test-non-dev | dryrun | execute | execute-non-dev )"
  echo
  echo "test:            create test orgs/spaces/apps/services/bindings"
  echo "                 as configured by internal variables"
  echo "test-non-dev:    similar to test, but will run against non-dev platforms"
  echo "dryrun:          show operations that would be run, without making any changes"
  echo "execute:         normal operation"
  echo "execute-non-dev: similar to execute, but will run against non-dev platforms"
  echo
  return 1
}

#### protect against accidental destruction of non-dev envs 
non_dev_protect() {
  local prod_url
  local prod_london_url
  local staging_url
  local target_url
  prod_url="https://api.cloud.service.gov.uk"
  prod_london_url="https://api.london.cloud.service.gov.uk"
  staging_url="https://api.london.staging.cloudpipeline.digital"
  target_url=$(get_target_url)
  if [[ "${target_url}" = "${prod_url}" ]] || [[ "${target_url}" = "${prod_london_url}" ]] || [[ "${target_url}" = "${staging_url}" ]]; then
    print_error "halting execution due to non-dev protection"
  fi
}

get_target_url() {
  local target_url
  target_url=$(jq -r '.Target' ~/.cf/config.json 2>&1)
  if [[ "${target_url}" = "" ]]; then
    print_error "could not determine target url"
  fi
  echo "${target_url}"
}

prepare_test() {
  if [[ -d "${test_dir}/tests" ]]; then
    rm -rf "${test_dir}/tests" >/dev/null 2>&1
  fi
  mkdir -p "${test_dir}/tests" >/dev/null 2>&1
}

cleanup_test() {
  rm -rf "${test_dir}/tests" >/dev/null 2>&1
}

get_test_manifest() {
  local name
  name="${1}"
  echo "applications:"
  echo "- name: ${name}"
  echo "  memory: 64M"
  echo "  services:"
  echo "  - ${name}"
}

#### test app/service using aws-s3-bucket service and staticfile buildpack
deploy_test_app() {
  local name
  local dir
  name="${1}"
  dir="${test_dir}/tests/${name}"
  mkdir -p "${dir}"
  get_test_manifest "${name}" >"${dir}/manifest.yml"
  echo "${name}" >"${dir}/index.html"
  touch "${dir}/Staticfile"
  do_cmd "cf create-service -w aws-s3-bucket default ${name}"
  cd "${dir}"
  do_cmd "cf push ${name}"
  add_output_row "${org_name}" "${space_name}" "${deploy_name}" "${deploy_name}" "deployed OK"
}

create_test_set() {
  print_banner "creating test set"
  local org_num
  local org_name
  local space_num
  local space_name
  local deploy_num
  local deploy_name
  for org_num in $(seq 1 "${test_org_count}"); do
    org_name="${test_prefix}-org-${org_num}"
    add_output_row "${org_name}" "-" "-" "-" "created OK" 
    do_cmd "cf create-org ${org_name}"
    do_cmd "cf target -o ${org_name}"
    for space_num in $(seq 1 "${test_space_count}"); do
      space_name="${org_name}-space-${space_num}"
      add_output_row "${org_name}" "${space_name}" "-" "-" "created OK"
      do_cmd "cf create-space ${space_name}"
      do_cmd "cf target -s ${space_name}"
      for deploy_num in $(seq 1 "${test_deploy_count}"); do
        deploy_name="${space_name}-app-${deploy_num}"
        deploy_test_app "${deploy_name}"
      done
    done
  done
}

get_test_orgs() {
  local org_num
  local org_name
  org_name=""
  for org_num in $(seq 1 "${test_org_count}"); do
    org_name="${org_name}${test_prefix}-org-${org_num},"
  done
  sed 's/,$//' < <(echo "${org_name}")
}

check_dependancies() {
  local bash_version
  bash_version=$(echo "${BASH_VERSION}" | cut -d'.' -f1)
  if [[ "${bash_version}" -lt 4 ]]; then
    print_error "requires bash version >= 4"
  fi
  if ! command -v cf >/dev/null 2>&1; then
    print_error "missing cf-cli" 
  fi
  if ! command -v jq >/dev/null 2>&1; then
    print_error "missing jq"
  fi
}

do_cmd() {
  local cmd
  cmd="${1}"
  local cmd_out
  if ! cmd_out=$(bash -c "${cmd}" 2>&1); then
    print_error "cmd: ${cmd}\nfailed with: ${cmd_out}"
  fi
}

cf_curl() {
  local url
  url="${1}"
  local json
  json=""
  local cmd_out
  if ! cmd_out=$(cf target 2>&1); then
    print_error "not logged in\n${cmd_out}"
  elif ! json=$(cf curl "${url}" 2>&1); then
    print_error "cf curl failed\n${json}"
  elif [[ "${json}" = "" ]]; then
    print_error "empty response from API"
  elif ! jq -e . < <(echo "${json}") >/dev/null 2>&1; then
    print_error "could not parse json response\n${json}"
  elif jq -e '.error_code' < <(echo "${json}") >/dev/null 2>&1; then
    print_error "json response contains error_code\n${json}"
  elif jq -e '.errors[]' < <(echo "${json}") >/dev/null 2>&1; then
    print_error "json response contains errors array\n${json}"
  else
    echo "${json}"
  fi
}

print_item() {
  local type
  type="${1}"
  local string
  string="${2}"
  local type_indents
  declare -A type_indents
  type_indents["org"]=0
  type_indents["space"]=2
  type_indents["app"]=3
  type_indents["svc"]=3
  local loop
  for ((loop=0; loop<${type_indents["${type}"]}; loop++)); do
    echo -n " "
  done
  echo -e "${type}: ${string}"
}

print_error() {
  local string
  string="${1}"
  echo -e "ERROR: ${string}" >&2
  return 1
}

#### limit orgs to test set in test mode
get_orgs() {
  local org_json
  if [[ "${test_orgs}" != "" ]]; then
    org_json=$(cf_curl "/v3/organizations?names=${test_orgs}")
  else
    org_json=$(cf_curl "/v3/organizations")
  fi
  get_resources "${org_json}"
}

get_spaces() {
  local guid
  guid="${1}"
  local space_json
  space_json=$(cf_curl "/v3/spaces?organization_guids=${guid}")
  get_resources "${space_json}"
}

get_service_instances() {
  local guid
  guid="${1}"
  local service_instance_json
  service_instance_json=$(cf_curl "/v3/service_instances?space_guids=${guid}")
  get_resources "${service_instance_json}"
}

get_service_credential_bindings() {
  local guid
  guid="${1}"
  local service_credential_binding_json
  service_credential_binding_json=$(cf_curl "/v3/service_credential_bindings?service_instance_guids=${guid}")
  get_resources "${service_credential_binding_json}"
}

#### allow certain resources to be processed last (service-brokers)
order_last() {
  local last_resource
  last_resource="${1}"
  local resources
  resources="${2}"
  if grep "${last_resource}" < <(echo "${resources}") >/dev/null 2>&1; then
    echo "${resources}" | grep -v "${last_resource}"
    echo "${last_resource}"
  else
    echo "${resources}"
  fi
}

get_resources() {
  local json
  json="${1}"
  jq -c -r '.resources[]' < <(echo "${json}") 2>/dev/null
}

get_resource_value() {
  local key
  key="${1}"
  local json
  json="${2}"
  jq -c -r ".${key}" < <(echo "${json}") 2>/dev/null
}

get_app_guid_for_binding() {
  local json
  json="${1}"
  jq -c -r '.relationships.app.data.guid' < <(echo "${json}") 2>/dev/null
}

get_app_name_for_guid() {
  local guid
  local app_json
  local app_resource
  guid="${1}"
  app_json=$(cf_curl "/v3/apps?guids=${guid}")
  app_resource=$(get_resources "${app_json}")
  get_resource_value "name" "${app_resource}"
}

get_cf_target() {
  local org_name
  local space_name
  org_name="${1}"
  space_name="${2}"
  do_cmd "cf target -o ${org_name} -s ${space_name}"
}

unbind_service() {
  local org_name
  local space_name
  local service_instance_name
  local app_name
  org_name="${1}"
  space_name="${2}"
  service_instance_name="${3}"
  app_name="${4}"
  get_cf_target "${org_name}" "${space_name}"
  do_cmd "cf unbind-service -w ${app_name} ${service_instance_name}"
  add_output_row "${org_name}" "${space_name}" "${service_instance_name}" "${app_name}" "unbound OK"
}

delete_service() {
  local org_name
  local space_name
  local service_instance_name
  org_name="${1}"
  space_name="${2}"
  service_instance_name="${3}"
  get_cf_target "${org_name}" "${space_name}"
  do_cmd "cf delete-service -w -f ${service_instance_name}"
  add_output_row "${org_name}" "${space_name}" "${service_instance_name}" "-" "deleted OK"
}

add_output_row() {
  local org
  local space
  local service
  local app
  local state
  local items
  local item
  local message
  org="${1}"
  space="${2}"
  service="${3}"
  app="${4}"
  state="${5}"
  items="org\nspace\nservice\napp"
  message=""
  for item in $(echo -e "${items}"); do
    if [[ "${!item}" != "-" ]]; then
      message="${message}${item}: ${!item}, "
    fi
  done
  echo "${message}state: ${state}"
  output_table="${output_table}\n${org}|${space}|${service}|${app}|${state}"
}

print_output_table(){
  echo -e "${output_table}" | column -s '|' -t
}

unbind_and_delete_all_services() {
  print_banner "unbind and delete all services"
  admin_org_json=$(cf_curl "/v3/organizations?names=admin")
  admin_org=$(get_resources "${admin_org_json}")
  admin_org_guid=$(get_resource_value "guid" "${admin_org}")
  service_broker_space_json=$(cf_curl "/v3/spaces?organization_guids=${admin_org_guid}&names=service-brokers")
  service_broker_space=$(get_resources "${service_broker_space_json}")
  org_resources=$(get_orgs)
  orgs=$(order_last "${admin_org}" "${org_resources}")
  for org in ${orgs}; do
    org_name=$(get_resource_value "name" "${org}")
    org_guid=$(get_resource_value "guid" "${org}")
    space_resources=$(get_spaces "${org_guid}")
    spaces=$(order_last "${service_broker_space}" "${space_resources}")
    for space in ${spaces}; do
      space_name=$(get_resource_value "name" "${space}")
      space_guid=$(get_resource_value "guid" "${space}")
      service_instances=$(get_service_instances "${space_guid}")
      for service_instance in ${service_instances}; do
        service_instance_name=$(get_resource_value "name" "${service_instance}")
        service_instance_guid=$(get_resource_value "guid" "${service_instance}")
        service_credential_bindings=$(get_service_credential_bindings "${service_instance_guid}")
        for service_credential_binding in ${service_credential_bindings}; do
          app_guid=$(get_app_guid_for_binding "${service_credential_binding}")
          app_name=$(get_app_name_for_guid "${app_guid}")
          if [[ "${mode}" != "dryrun" ]]; then
            unbind_service "${org_name}" "${space_name}" "${service_instance_name}" "${app_name}"
            #TODO: parallelize - get $! pid and push to array - exclude service-broker space
          else
            add_output_row "${org_name}" "${space_name}" "${service_instance_name}" "${app_name}" "unbound OK (dryrun)"
          fi
        done
        if [[ "${mode}" != "dryrun" ]]; then
          delete_service "${org_name}" "${space_name}" "${service_instance_name}"
          #TODO: parallelize - get $! pid and push to array - exclude admin org
        else
          add_output_row "${org_name}" "${space_name}" "${service_instance_name}" "-" "deleted OK (dryrun)"
        fi
      done
    done
  done
}

print_banner() {
  local message
  message="${1}"
  local decal
  decal="===================="
  echo -e "\n${decal} ${message} ${decal}\n"
}

check_dependancies
if [[ "$#" -ne 1 ]]; then
  usage
fi

mode="${1}"

if [[ "${mode}" = "test" ]]; then
  non_dev_protect
  prepare_test
  create_test_set
  test_orgs=$(get_test_orgs)
  unbind_and_delete_all_services
  cleanup_test
elif [[ "${mode}" = "test-non-dev" ]]; then
  prepare_test
  create_test_set
  test_orgs=$(get_test_orgs)
  unbind_and_delete_all_services
  cleanup_test
elif [[ "${mode}" = "dryrun" ]]; then
  unbind_and_delete_all_services
elif [[ "${mode}" = "execute" ]]; then
  non_dev_protect
  unbind_and_delete_all_services
elif [[ "${mode}" = "execute-non-dev" ]]; then
  unbind_and_delete_all_services
else
  usage
fi

# TODO: add column binary to the build docker container so we can use column to print a pretty results table
#print_banner "results"
#print_output_table
print_banner "completed"
