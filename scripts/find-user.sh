#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT=$0

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<EOF
Usage:

  $SCRIPT -e <email> [-o <orgname>]

$SCRIPT loops through every page the API returns looking for a user with a
specific email address.

Requirements:

 * You must login with the cf client with an "admin" user.
 * You must have a functional aws client with credentials configured.

Where:
  -e <email>   User email to be used for comparision whilst
               looping through the list.

  -o <orgname> Organisation to be used for filtering whilst querying
               the CF API for users. It has a potential to quicken
               your search and/or limit number of requests.

EOF
  exit 1
}

abort_usage() {
  echo -e "${COL_RED:-}${COL_LIGHT:-}ERROR:${COL_RESET:-} $*" 1>&2
  usage
  exit 1
}

check_params_and_environment() {
  if [ -z "${EMAIL:-}" ]; then
    abort_usage "Email must be defined"
  fi

  local email_expr="^[A-Za-z0-9._%+\'-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$"
  if ! [[ "${EMAIL}" =~ ${email_expr} ]]; then
    abort "You must specify a valid email"
  fi

  if ! jq -V >/dev/null 2>&1; then
    abort "You need to have jq installed"
  fi

  if ! cf orgs >/dev/null 2>&1; then
    abort "You need to be logged into CF CLI"
  fi

}

find_user() {
  path="$*"
  obj=$(cf curl "$path")
  # shellcheck disable=SC2001
  page=$(echo "$path" | sed -e 's/.*&page=\([[:digit:]]*\).*/\1/')

  if [ "${#page}" -gt 5  ]; then
    page=1
  fi
  info "Page: $page/$(echo "$obj" | jq -r '.total_pages')."

  user=$(echo "$obj" | jq -r -C '.resources[] | select(.entity.username=="'"${EMAIL}"'")')

  if [[ -z "$user" ]]; then
    nextURL=$(echo "$obj" | jq -r '.next_url')

    if [ "$nextURL" = "null" ]; then
      abort "This ain't the user you're looking for..."
    else
      find_user "$nextURL"
    fi
  else
    success "$user"
  fi
}

find_org_user() {
  org=$(cf org "$ORG" --guid)

  find_user "/v2/users?q=organization_guid:$org"
}

while [[ $# -gt 0 ]]; do
  key="$1"
  shift
  case $key in
    -o|--org)
      ORG="$1"
      shift
    ;;
    -e|--email)
      EMAIL="$1"
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

if [ -n "${ORG:-}" ]; then
  find_org_user
else
  find_user "/v2/users"
fi
