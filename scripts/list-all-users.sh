#!/bin/bash

set -e -u -o pipefail

uaac_endpoint=$(cf curl /v2/info | jq -r '.authorization_endpoint')
oauth_token=$(cf oauth-token)

get_number_of_users() {
  curl --silent --fail "$uaac_endpoint/Users?count=0" -H "Authorization: $oauth_token" | jq -r '.totalResults'
}

get_users() {
  curl --silent --fail "$uaac_endpoint/Users?attributes=userName&startIndex=$1&count=500" -H "Authorization: $oauth_token" | jq -r '.resources[].userName'
}

for s in $(seq 0 500 "$(get_number_of_users)"); do
  get_users "$s"
done
