#!/bin/bash

load_colors() {
  if [ -t 1 ] ; then
    export ESC_SEQ="\\x1b["
    export COL_RESET="${ESC_SEQ}39;49;00m"
    export COL_LIGHT="${ESC_SEQ}1m"
    export COL_DIM="${ESC_SEQ}2m"
    export COL_BLINK="${ESC_SEQ}5m"
    export COL_RED="${ESC_SEQ}31m"
    export COL_GREEN="${ESC_SEQ}32m"
    export COL_YELLOW="${ESC_SEQ}33m"
    export COL_BLUE="${ESC_SEQ}34m"
    export COL_MAGENTA="${ESC_SEQ}35m"
    export COL_CYAN="${ESC_SEQ}36m"
  fi
}

abort() {
  echo -e "${COL_RED:-}${COL_LIGHT:-}ERROR:${COL_RESET:-} $*" 1>&2
  exit 1
}

info() {
  echo -e "${COL_CYAN:-}INFO:${COL_RESET:-} $*"
}

success() {
  echo -e "${COL_GREEN:-}SUCCESSFUL:${COL_RESET:-} $*"
}

check_aws_account_used() {
  required_account="${1}"
  account_alias=$(aws iam list-account-aliases | grep gov-paas | tr -d '" ')

  if [[ "${account_alias}" != "gov-paas-${required_account}" ]]; then
    echo "Required AWS account is ${required_account}, but your aws-cli is using keys for ${account_alias}"
    exit 1
  fi
}

check_logged_in_cf() {
  required_api_endpoint="${1}"
  api_result=$(cf api)
  if ! [[ "${api_result}" =~ ${required_api_endpoint} ]]; then
    echo "Required cf api endpoint is ${required_api_endpoint}, but your cf reports '${api_result}'"
    exit 1
  fi

  logged_in_pattern="Not logged in"
  if [[ $(cf target) =~ ${logged_in_pattern} ]]; then
    echo "Not logged in. Please 'cf login' and retry."
    exit 1
  fi
}
