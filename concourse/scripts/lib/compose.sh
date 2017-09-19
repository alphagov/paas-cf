#!/bin/sh
set -e
set -u

get_compose_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/compose-secrets.yml"
  export compose_api_key
  export compose_billing_email
  export compose_billing_password
  if aws s3 ls "${secrets_uri}" > /dev/null ; then
    secrets_file=$(mktemp -t compose-secrets.XXXXXX)

    aws s3 cp "${secrets_uri}" "${secrets_file}"
    compose_api_key=$("${SCRIPT_DIR}"/val_from_yaml.rb compose_api_key "${secrets_file}")
    compose_billing_email=$("${SCRIPT_DIR}"/val_from_yaml.rb compose_billing_email "${secrets_file}")
    compose_billing_password=$("${SCRIPT_DIR}"/val_from_yaml.rb compose_billing_password "${secrets_file}")

    rm -f "${secrets_file}"
  fi
}
