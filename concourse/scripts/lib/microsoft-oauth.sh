#!/bin/sh
set -e
set -u

get_microsoft_oauth_secrets() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/microsoft-oauth-secrets.yml"
  export microsoft_oauth_tenant_id
  export microsoft_oauth_client_id
  export microsoft_oauth_client_secret
  secrets_size=$(aws s3 ls "${secrets_uri}" | awk '{print $3}')
  if [ "${secrets_size}" != 0 ] && [ -n "${secrets_size}" ]  ; then
    secrets_file=$(mktemp -t microsoft-oauth-secrets.XXXXXX)

    aws s3 cp "${secrets_uri}" "${secrets_file}"
    microsoft_oauth_tenant_id=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.microsoft_oauth_tenant_id "${secrets_file}")
    microsoft_oauth_client_id=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.microsoft_oauth_client_id "${secrets_file}")
    microsoft_oauth_client_secret=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.microsoft_oauth_client_secret "${secrets_file}")

    rm -f "${secrets_file}"
  fi
}
