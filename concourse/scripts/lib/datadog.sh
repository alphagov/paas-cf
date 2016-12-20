#!/bin/sh
set -e
set -u

get_datadog_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/datadog-secrets.yml"
  export datadog_api_key
  export datadog_app_key
  if aws s3 ls "${secrets_uri}" > /dev/null ; then
    secrets_file=$(mktemp -t datadog-secrets.XXXXXX)

    aws s3 cp "${secrets_uri}" "${secrets_file}"
    datadog_api_key=$("${SCRIPT_DIR}"/val_from_yaml.rb datadog_api_key "${secrets_file}")
    datadog_app_key=$("${SCRIPT_DIR}"/val_from_yaml.rb datadog_app_key "${secrets_file}")

    rm -f "${secrets_file}"
  fi
}
