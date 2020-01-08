#!/bin/bash

set -eo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

ensure_env_vars() {
  if [ -z "${AWS_ACCOUNT}" ] || [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
    echo "Must set AWS_ACCOUNT, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
    exit 1
  fi

  if ! [[ "${AWS_ACCOUNT:-}" =~ ^(dev|ci|staging|prod)$ ]]; then
    echo "You must set AWS_ACCOUNT with one of: dev|ci|staging|prod"
    exit 1
  fi

  STS_TOKEN_DURATION="${STS_TOKEN_DURATION:-43200}"
  STS_TOKEN_DIRECTORY="${STS_TOKEN_DIRECTORY:-${HOME}/.aws_sts_tokens}"

  STS_TOKEN_STALESNESS_THRESHOLD=600
  TOKEN_FILE="${STS_TOKEN_DIRECTORY}/${AWS_ACCOUNT}.sh"
  unset AWS_SESSION_TOKEN
}

ensure_token_dir() {
  if [ ! -d "${STS_TOKEN_DIRECTORY}" ]; then
      mkdir "${STS_TOKEN_DIRECTORY}"
  fi
}

delete_stale_tokens() {
  # we can't use last modified time since we want the duration to be configurable

  now=$(date +%s)
  token_files=$(find "${STS_TOKEN_DIRECTORY}" -name "*.sh" -type f)

  for f in $token_files; do
    expire_time=$(head -1 "${f}" | cut -d ":" -f 2)
    if [ "${expire_time}" -lt "${now}" ]; then
      rm "${f}"
    fi
  done
}

generate_new_token() {
  read -r -p "Enter MFA code for ${AWS_ACCOUNT}: " mfa_token

  user_arn=$(aws sts get-caller-identity --query Arn --output text)
  token_arn=${user_arn/:user/:mfa}

  expires=$(($(date +%s) + STS_TOKEN_DURATION - STS_TOKEN_STALESNESS_THRESHOLD))
  echo "# EXPIRES:${expires}" > "${TOKEN_FILE}"
  chmod 600 "${TOKEN_FILE}"
  trap 'rm ${TOKEN_FILE}' ERR

  aws sts get-session-token \
    --serial-number "${token_arn}" \
    --duration-seconds "${STS_TOKEN_DURATION}" \
    --output text \
    --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]" \
    --token-code "${mfa_token}" | \
      awk '{ print "export AWS_ACCESS_KEY_ID=\"" $1 "\"\n" "export AWS_SECRET_ACCESS_KEY=\"" $2 "\"\n" "export AWS_SESSION_TOKEN=\"" $3 "\"" }' >> "${TOKEN_FILE}"
}

ensure_env_vars
ensure_token_dir
delete_stale_tokens

if [ ! -e "${TOKEN_FILE}" ]; then
  generate_new_token
fi
