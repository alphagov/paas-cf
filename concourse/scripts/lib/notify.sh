#!/bin/sh
set -e
set -u

get_notify_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/notify-secrets.yml"
  export notify_api_key
  secrets_size=$(aws s3 ls "${secrets_uri}" | awk '{print $3}')
  if [ "${secrets_size}" != 0 ] && [ -n "${secrets_size}" ]  ; then
    secrets_file=$(mktemp -t notify-secrets.XXXXXX)

    aws s3 cp "${secrets_uri}" "${secrets_file}"
    notify_api_key=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.notify_api_key "${secrets_file}")

    rm -f "${secrets_file}"
  fi
}
