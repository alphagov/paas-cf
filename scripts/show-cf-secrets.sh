#!/usr/bin/env bash

requested_secrets=( "$@" )

raw_secrets="$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/cf-vars-store.yml" -)"

for secret in "${requested_secrets[@]}"; do
  value=$(echo "${raw_secrets}" | grep "${secret}" | cut -d ':' -f 2 | tr -d ' ')
  key=$(echo "${secret}" | tr '[:lower:]' '[:upper:]')
  echo "export ${key}=${value}"
done
