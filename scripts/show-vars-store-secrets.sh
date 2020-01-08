#!/usr/bin/env bash

set -euo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

vars_store=$1
shift
requested_secrets="$*"

if raw_secrets="$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/${vars_store}.yml" -)"; then
  echo "$raw_secrets" \
  | awk -F ': ' \
        -v secrets_regex="^($(echo "$requested_secrets" | tr ' ' '|'))\$" \
        '$1 ~ secrets_regex {print "export " toupper($1) "=" $2}'
else
  echo "# $vars_store not found, skipping"
fi
