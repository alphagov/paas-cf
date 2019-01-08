#!/bin/bash

set -eu

CF_HOME=${CF_HOME:-~}
UAA_TOKEN=$(cf oauth-token)
UAA_API=$(jq -r '.UaaEndpoint' < "${CF_HOME}/.cf/config.json")

# Assert logged in
cf target > /dev/null

TARGET=$(jq -r '.Target' < "${CF_HOME}/.cf/config.json")
echo "Targetting CF API: $TARGET" 1>&2

paginate() {
  next_url=
  page=1
  rpp="$1"
  path="$2"
  while [ "$next_url" != 'null' ]; do
    url="${path}?results-per-page=${rpp}&page=${page}"
    organizations=$(cf curl "$url")
    echo "$organizations" | jq '{resources}'
    next_url=$(echo "$organizations" | jq -r ".next_url")
    ((page++))
  done
}

get_resources() {
  paginate "$1" "$2" | jq 'reduce inputs as $i (.; .resources += $i.resources)'
}

org_by_guid() {
  guid="$1"
  orgs="$2"
  echo "$orgs" | jq ".resources[] | select(.metadata.guid == \"$guid\")"
}

managers_in_org() {
  org="$1"
  managers_url=$(echo "$org" | jq -r '.entity.managers_url')
  cf curl "$managers_url"
}

users_in_org() {
  org="$1"
  users_url=$(echo "$org" | jq -r '.entity.users_url')
  cf curl "$users_url"
}

apps_in_state() {
  desired_state="$1"
  org="$2"
  c=0
  spaces=$(cf curl "$(echo "$org" | jq -r '.entity.spaces_url')")
  apps_urls=$(echo "$spaces" | jq -r '.resources[].entity.apps_url')
  for apps_url in $apps_urls; do
    states=$(cf curl "$apps_url" | jq -r '.resources[].entity.state')
    for state in $states; do
      if [ "$state" == "$desired_state" ]; then
        ((c++))
      fi
    done
  done
  echo "$c"
}

services_in_org() {
  guid="$1"
  summary=$(cf curl "/v2/organizations/${guid}/summary")
  echo "$summary" | jq -r "reduce .spaces[] as \$space (0; . + \$space.service_count)"
}

find_latest_login() {
  users="$1"
  uaa_users=$(curl -s -H "Authorization: $UAA_TOKEN" "$UAA_API/Users")
  user_guids=$(echo "$users" | jq -r '.resources[].metadata.guid')
  last_logon_times=
  for user_guid in $user_guids; do
    last_logon_time=$(echo "$uaa_users" | jq ".resources[] | select(.id==\"$user_guid\") | .lastLogonTime")
    if [ "$last_logon_time" != null ]; then
      last_logon_times="${last_logon_times} ${last_logon_time}"
    fi
  done
  echo "$last_logon_times" | tr ' ' '\n' | sort | tail -n 1
}

quota_name() {
  quota_url=$( jq -r '.entity.quota_definition_url')
  cf curl "$quota_url" | jq -r '.entity.name'
}

orgs=$(get_resources 100 "/v2/organizations")
org_guids=$(echo "$orgs" | jq -r '.resources[].metadata.guid')

echo "name,guid,created_at,updated_at,managers,users,running_apps,stopped_apps,services,last_logon_time,quota,org_manager_emails"
for guid in $org_guids; do

  org=$(org_by_guid "$guid" "$orgs")

  # Name
  name=$(echo "$org" | jq -r '.entity.name')

  # Created/Updated at
  created_at="$(echo "$org" | jq -r '.metadata.created_at')"
  updated_at="$(echo "$org" | jq -r '.metadata.updated_at')"

  # Number of managers
  managers=$(managers_in_org "$org")
  managers_count=$(echo "$managers" | jq -r '.resources | length')

  # Number of users
  users=$(users_in_org "$org")
  users_count=$(echo "$users" | jq -r '.resources | length')

  # Apps & services
  running_apps=$(apps_in_state "STARTED" "$org")
  stopped_apps=$(apps_in_state "STOPPED" "$org")
  services=$(services_in_org "$guid")

  # Most recent login time across all users in an org
  last_logon_time=$(find_latest_login "$users")

  # quota
  quota=$(echo "${org}" | quota_name "$guid")

  # Space-separated list of emails of org managers
  org_manager_emails=$(echo "$managers" | jq -r ".resources[].entity.username")
  org_manager_emails=$(echo "$org_manager_emails" | tr '\n' ' ')

  echo "$name,$guid,$created_at,$updated_at,$managers_count,$users_count,$running_apps,$stopped_apps,$services,$last_logon_time,$quota,$org_manager_emails"
done
