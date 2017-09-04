#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT=$0
COMPOSE_API_URL='https://api.compose.io/2016-07'

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<EOF
  Usage:
    $SCRIPT [-n <name>] -o <orgname> -s <space[,space,...]> -t <type>

$SCRIPT will manually create an instance
of defined type with the use of compose API and assign it to the specific
organisation as a CloudFoundry User Provided Service.

Requirements:

 * You must login with the cf client with an "admin" user.
 * You must have the compose_api_token environment variable set.

Where:
  -n <name>    Name of the service that should be created. If flag is not set
               a default value will be generated.

  -o <orgname> Organisation the service should be assigned to upon creation.

  -s <space>   Comma separated space names the service should be assigned to
               upon creation.

  -t <type>    Service type to be created. Supported:
               mongodb, redis, postgresql, elastic_search, rethink, rabbitmq,
               etcd, scylla, mysql, disque
EOF
exit 1
}

get_cluster_data(){
  compose_cluster_data=$(curl -s -X GET "${COMPOSE_API_URL}/clusters" \
    -H "Authorization: Bearer ${COMPOSE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    2>/dev/null | jq -r ._embedded.clusters[0])

  compose_cluster_id=$(echo "${compose_cluster_data}" | jq -r .id)
  compose_account_id=$(echo "${compose_cluster_data}" | jq -r .account_id)
}

prepare_name() {
  id=$(date +%s | md5)
  deployment_name=$(echo "alpha-${TYPE}-${ORG}-${id}" | cut -c1-50)
}

provision_instance() {
  local body
  body=$(printf '{
    "deployment": {
      "name": "%s",
      "account_id": "%s",
      "cluster_id": "%s",
      "type": "%s"
    }
  }' "${SERVICE_NAME:-$deployment_name}" "${compose_account_id}" "${compose_cluster_id}" "${TYPE}")

  uri=$(curl -s -X POST "${COMPOSE_API_URL}/deployments" \
      -H "Authorization: Bearer ${COMPOSE_API_TOKEN}" \
      -H "Content-Type: application/json; charset=utf-8" \
      -d "${body}" | jq -r .connection_strings.direct[0])

  pattern='^(([a-z]{3,5})://)?((([^:\/]+)(:([^@\/]*))?@)?([^:\/?]+)(:([0-9]+))?)(\/[^?]*)?(\?[^#]*)?(#.*)?$'
  [[ "$uri" =~ $pattern ]] || return 1;

  uri=${BASH_REMATCH[0]}
  uri_user=${BASH_REMATCH[5]}
  uri_password=${BASH_REMATCH[7]}
  uri_host=${BASH_REMATCH[8]}
  uri_port=${BASH_REMATCH[10]}
}

create_user_provided_service() {
  local body
  body=$(printf '{
    "username": "%s",
    "password": "%s",
    "host": "%s",
    "port": "%s",
    "uri": "%s"
  }' "${uri_user}" "${uri_password}" "${uri_host}" "${uri_port}" "${uri}")

  IFS=',';
  for i in $(printf "%s" "${SPACE}")
  do
    info "Targeting organisation '${ORG}' and space '${i}'."

    cf target -o "${ORG}" -s "${i}"

    warning "Please bear in mind, if post to this message you'll encounter an error, you will need to manually deprovision the instance: '${deployment_name}'"

    cf create-user-provided-service "${SERVICE_NAME:-$deployment_name}" -p "${body}"
  done
}

check_params_and_environment() {
  if [ -z "${COMPOSE_API_TOKEN:-}" ]; then
    echo "COMPOSE_API_TOKEN must be exported"
    usage
    exit 1
  fi
  if [ -z "${TYPE:-}" ]; then
    echo "Service type flag must be provided"
    usage
    exit 1
  fi
  if [ -z "${ORG:-}" ]; then
    echo "Organisation flag must be provided"
    usage
    exit 1
  fi
  if [ -z "${SPACE:-}" ]; then
    echo "Space flag must be provided"
    usage
    exit 1
  fi
  if [ -n "${SERVICE_NAME:-}" ]; then
    if [ "${#SERVICE_NAME}" -gt 50 ]; then
      abort "Name must be no longer than 50 characters."
    fi
  fi
}

warning() {
  echo -e "${COL_YELLOW:-}WARNING:${COL_RESET:-} $*"
}

while [[ $# -gt 0 ]]; do
  key="$1"
  shift
  case $key in
    -o|--org|--organisation)
      ORG="$1"
      shift
    ;;
    -s|--space)
      SPACE="$1"
      shift
    ;;
    -t|--type)
      TYPE="$1"
      shift
    ;;
    -n|--name)
      SERVICE_NAME="$1"
      shift
    ;;
    *)
      # unknown option
      usage
    ;;
  esac
done

load_colors
check_params_and_environment
prepare_name
get_cluster_data
provision_instance
create_user_provided_service

success "All done!"
warning "You may need to manually setup the whitelisting for the above instance."
