#!/usr/bin/env bash

set -e -u -o pipefail

if [[ $# -lt 2 ]]; then
  >&2 echo "Usage: $0 <organisation> <email of user to reset>"
  exit 1
else
  org=$1
  email=$2
fi

info=$(cf curl /v2/info)
uaa_endpoint=$(jq -r '.token_endpoint' <<< "$info")
token=$(cf oauth-token)
org_guid=$(cf org "$org" --guid)

users=$(curl \
  --silent \
  --fail \
  --header "Authorization: $token" \
  --get \
  --data-urlencode "filter=userName eq '$email'" \
  "$uaa_endpoint/Users")

if jq -e '.resources | length != 1' <<< "$users" > /dev/null; then
  >&2 echo "$users"
  >&2 echo "Expected to find exactly one user for email $email"
fi

user_guid=$(jq -r '.resources[0].id' <<< "$users")

if curl \
  --silent \
  --fail \
  --request PATCH \
  --header "Authorization: $token" \
  --header "If-Match: *" \
  --header "Content-Type: application/json" \
  --data '{"verified": false}' \
  "$uaa_endpoint/Users/$user_guid" > /dev/null; then

  echo "Successfully set verified status for $email to false.

You can now send this user a new invitation email by visiting the following URL and clicking the 'Resend user invite' button:

https://admin.cloud.service.gov.uk/organisations/$org_guid/users/$user_guid

This will allow them to set a new password."
else

  >&2 echo "Failed to set verified status on user $email"
  exit 1

fi

