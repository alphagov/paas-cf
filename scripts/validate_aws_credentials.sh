#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if [ "${SKIP_AWS_CREDENTIAL_VALIDATION:-}" == "true" ]  ; then
  exit 0
fi

if [ -z "$AWS_SESSION_TOKEN" ]; then
  echo "No temporary AWS credentials found, please run create_sts_token.sh"
  exit 255;
fi

if [ -z "$AWS_ACCOUNT" ]; then
  echo "No AWS_ACCOUNT specified, please populate the environment variable"
  exit 255;
fi

if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "Current AWS credentials are invalid, please refresh them using create_sts_token.sh"
  exit 255;
fi

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"
check_aws_account_used "${AWS_ACCOUNT}"
