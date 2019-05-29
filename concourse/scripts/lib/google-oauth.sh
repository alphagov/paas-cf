#!/bin/sh
set -e
set -u

get_google_oauth_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/google-oauth-secrets.yml"
  export google_oauth_client_id
  export google_oauth_client_secret
  secrets_size=$(aws s3 ls "${secrets_uri}" | awk '{print $3}')
  if [ "${secrets_size}" != 0 ] && [ -n "${secrets_size}" ]  ; then
    secrets_file=$(mktemp -t google-oauth-secrets.XXXXXX)

    aws s3 cp "${secrets_uri}" "${secrets_file}"
    google_oauth_client_id=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.google_oauth_client_id "${secrets_file}")
    google_oauth_client_secret=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.google_oauth_client_secret "${secrets_file}")

    rm -f "${secrets_file}"
  fi
}
