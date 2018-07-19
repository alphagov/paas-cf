#!/bin/sh
set -e
set -u

get_aiven_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/aiven-secrets.yml"
  export aiven_api_token
  if aws s3 ls "$secrets_uri" > /dev/null ; then
    secrets_file=$(mktemp -t aiven-secrets.XXXXXX)

    aws s3 cp "$secrets_uri" "$secrets_file"
    aiven_api_token=$("${SCRIPT_DIR}/val_from_yaml.rb" aiven_api_token "$secrets_file")

    rm -f "$secrets_file"
  fi
}
