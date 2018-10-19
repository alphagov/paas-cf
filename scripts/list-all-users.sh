#!/bin/bash

set -e -u -o pipefail

uaac_endpoint=$(cf curl /v2/info | jq -r '.authorization_endpoint')
oauth_token=$(cf oauth-token)

get_number_of_users() {
  if ! curl --silent --fail "$uaac_endpoint/Users?count=0" -H "Authorization: $oauth_token" | jq -r '.totalResults'; then
    >&2 echo 'Error talking to UAA - are you logged in as an admin?'
    exit 1
  fi
}

get_users() {
  if ! curl --silent --fail "$uaac_endpoint/Users?attributes=userName&startIndex=$1&count=500" -H "Authorization: $oauth_token" | jq -r '.resources[].userName'; then
    >&2 echo 'Error getting users from UAA - aborting'
    exit 2
  fi
}

for s in $(seq 0 500 "$(get_number_of_users)"); do
  get_users "$s"
done | sort --field-separator=@ --key=2 --key=1
