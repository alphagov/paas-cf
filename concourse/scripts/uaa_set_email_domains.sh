#!/bin/bash

set -e -u -o pipefail

# SCRIPT

email_domains=${1}

basic_auth_client_creds=$(echo -n "admin:${UAA_ADMIN_CLIENT_SECRET}" | base64)
access_token="$(curl \
  --silent \
  --fail \
  --header "Authorization: Basic ${basic_auth_client_creds}" \
  --data 'grant_type=client_credentials' \
  "${LOGIN_URL}/oauth/token" | jq -r '.access_token')"

uaa_idp_json=$(curl --silent --fail --header "Authorization: bearer ${access_token}" "${UAA_URL}/identity-providers/" | jq -r '.[] | select(.type == "uaa")')
uaa_idp_guid=$(jq -r '.id' <<< "$uaa_idp_json")
uaa_idp_config=$(jq -r '.config' <<< "$uaa_idp_json")

updated_uaa_idp_config=$(jq --compact-output ".emailDomain = ${email_domains}" <<< "${uaa_idp_config}")
updated_uaa_idp_json=$(jq --compact-output --arg config "${updated_uaa_idp_config}" '.config = $config' <<< "${uaa_idp_json}")

if curl --silent --fail \
  --header "Content-Type: application/json" \
  --header "Authorization: bearer ${access_token}" \
  --request PUT \
  --data "${updated_uaa_idp_json}" \
  "${UAA_URL}/identity-providers/${uaa_idp_guid}"; then

  echo -e '\n\nSuccessfully updated emailDomain for uaa identity provider'
else
  >&2 echo 'Failed to update emailDomain for uaa identity provider'
  exit 1
fi
