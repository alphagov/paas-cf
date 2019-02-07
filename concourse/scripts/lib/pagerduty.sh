#!/bin/sh
set -e
set -u

get_pagerduty_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/pagerduty-secrets.yml"
  export alertmanager_pagerduty_service_key
  if aws s3 ls "$secrets_uri" > /dev/null ; then
    secrets_file=$(mktemp -t pagerduty-secrets.XXXXXX)

    aws s3 cp "$secrets_uri" "$secrets_file"
    alertmanager_pagerduty_service_key=$("${SCRIPT_DIR}/val_from_yaml.rb" alertmanager_pagerduty_service_key "$secrets_file")

    rm -f "$secrets_file"
  fi
}
