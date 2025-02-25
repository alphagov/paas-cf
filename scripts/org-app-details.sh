#!/usr/bin/env bash
#
# This script gathers information on all spaces in the current CF environment.
# It will output a CSV with the following columns:
#
# - space_name
# - organization_id
# - organization_name
# - app_names
# - service_count_within_space
#
# I run it like this:
#
# cf login -a api.london.cloud.service.gov.uk --sso
# ./scripts/org-app-details.sh > ~/Desktop/org-app-details.csv
# cf login -a api.cloud.service.gov.uk --sso
# ./scripts/org-app-details.sh > ~/Desktop/org-app-details.csv

set -e

if [ "${BASH_VERSION%%.*}" -lt 4 ]; then
   echo "Error: This script requires Bash version 4 or later."
   echo "Simple solution on MacOS: brew install bash"
   exit 1
fi

# Check if logged in:
if ! cf target > /dev/null 2>&1; then
    echo "Not logged into CF, please log in and retry"
    exit 1
fi

optional_orgs=$1

if [ "$optional_orgs" = "help" ] || [ "$optional_orgs" = "--help" ] || [ "$optional_orgs" = "-h" ]; then
  echo "Usage: $0 [comma separated list of org names]"
  echo "If no orgs are specified, all orgs will be checked"
  exit 0
fi

# Prepare output:
echo "space_id,space_name,organization_id,organization_name,app_names,service_count_within_space"

declare -A orgs
declare -A spaces

# Get organizations:
if [ -n "$optional_orgs" ]; then
  orgs_query=$(cf curl "/v3/organizations?names=$optional_orgs&per_page=5000&order_by=name" | jq -rc '.resources[] | {guid: .guid, name: .name}')
else
  orgs_query=$(cf curl "/v3/organizations?per_page=5000&order_by=name" | jq -rc '.resources[] | {guid: .guid, name: .name}')
fi

while IFS= read -r line; do
  org_guid=$(echo "$line" | jq -r '.guid')
  org_name=$(echo "$line" | jq -r '.name')
  orgs["$org_guid"]="$org_name"
done <<< "$orgs_query"

# Get spaces for each organization:
for org_guid in "${!orgs[@]}"; do
  org_name=${orgs["$org_guid"]}
  spaces_query=$(cf curl "/v3/spaces?organization_guids=$org_guid&per_page=5000" | jq -rc '.resources[] | {guid: .guid, name: .name, org_name: "'"${org_name}"'"}')
  while IFS= read -r space; do
    space_guid=$(echo "$space" | jq -r '.guid')
    space_name=$(echo "$space" | jq -r '.name')
    spaces["$space_guid"]="$space_name,$org_name,$org_guid"
  done <<< "$spaces_query"
done

# For each space, get apps and services:
for space_guid in "${!spaces[@]}"; do
  space_info=${spaces["$space_guid"]}
  space_name=$(echo "$space_info" | cut -d ',' -f 1)
  org_name=$(echo "$space_info" | cut -d ',' -f 2)
  org_guid=$(echo "$space_info" | cut -d ',' -f 3)

  # Retrieve apps in the space
  apps=$(cf curl "/v3/apps?space_guids=$space_guid&per_page=5000")
  app_names=$(echo "$apps" | jq -r '[.resources[].name] | join(", ")')

  # Retrieve services in the space
  services=$(cf curl "/v3/service_instances?space_guids=$space_guid&per_page=5000")
  service_count=$(echo "$services" | jq '.pagination.total_results')

  # Append result:
  echo "$space_guid,$space_name,$org_guid,$org_name,\"$app_names\",$service_count"
done
