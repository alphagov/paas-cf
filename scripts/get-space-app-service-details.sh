#!/usr/bin/env bash
#
# This script gathers information on all non-test spaces in a CF environment.
# It will gather information on all spaces if the $TEST_ORGS env var is set.
# Test orgs are ones whose name begin with either "ASATS" or "SMOKE"
#
# It will output a CSV with the following columns:
#
# - space_name
# - organization_name
# - app_names
# - service_count_within_space
#
# run:
#
# cf login -a api.london.cloud.service.gov.uk --sso
# ./scripts/get-space-app-service-details.sh > ~/Desktop/space_app_service_status.csv dit-staging,dit-services

set -e

if [ "${BASH_VERSION%%.*}" -lt 4 ]; then
   echo "Error: This script requires Bash version 4 or later." >&2
   echo "Simple solution on MacOS: brew install bash" >&2
   exit 1
fi

# Check if logged in:
if ! cf target > /dev/null 2>&1; then
    echo "Not logged into CF, please log in and retry" >&2
    exit 1
fi

optional_orgs=$1

if [ "$optional_orgs" = "help" ] || [ "$optional_orgs" = "--help" ] || [ "$optional_orgs" = "-h" ]; then
  echo "Usage: $0 [comma separated list of org names]" >&2
  echo "If no orgs are specified, all orgs will be checked" >&2
  exit 0
fi

if [ -n "$optional_orgs" ]; then
  echo "Filtering to a comma separated list of orgs: $optional_orgs" >&2
fi

# Prepare output:
echo "space_name,organization_name,app_names,service_count_within_space"

declare -A orgs
declare -A spaces

# Get orgs:
if [ -n "$optional_orgs" ]; then
  orgs_query=$(cf curl "/v3/organizations?names=$optional_orgs&per_page=5000&order_by=name" | jq -rc '.resources[] | {guid: .guid, name: .name}')
else
  orgs_query=$(cf curl "/v3/organizations?per_page=5000&order_by=name" | jq -rc '.resources[] | {guid: .guid, name: .name}')
fi

while IFS= read -r line; do
  org_guid=$(echo "$line" | jq -r '.guid')
  org_name=$(echo "$line" | jq -r '.name')

  # Check for empty or invalid values
  if [ -z "$org_guid" ] || [ -z "$org_name" ]; then
    echo "Warning: Encountered an org with no GUID or name, skipping." >&2
    continue
  fi

  if [[ -z "${TEST_ORGS}" && ( "$org_name" == ASATS* || "$org_name" == SMOKE*) ]]; then
    echo "Warning: Skipping test org $org_name" >&2
    continue
  fi

  orgs["$org_guid"]="$org_name"
done <<< "$orgs_query"

# Get spaces for each org:
for org_guid in "${!orgs[@]}"; do
  org_name=${orgs["$org_guid"]}

  spaces_query=$(cf curl "/v3/spaces?organization_guids=$org_guid&per_page=5000" | jq -rc '.resources[] | {guid: .guid, name: .name, org_name: "'"${org_name}"'"}')

  while IFS= read -r space; do
    space_guid=$(echo "$space" | jq -r '.guid')
    space_name=$(echo "$space" | jq -r '.name')

    # Ensure that space_guid and space_name are not empty
    if [ -z "$space_guid" ] || [ -z "$space_name" ]; then
      echo "Warning: Encountered a space with no GUID or name, skipping." >&2
      continue
    fi

    # Debug output to check values
    echo "Adding space: GUID=$space_guid, Name=$space_name, Org=$org_name" >&2

    spaces["$space_guid"]="$space_name,$org_name"
  done <<< "$spaces_query"
done

# For each space, get apps and services:
for space_guid in "${!spaces[@]}"; do
  space_info=${spaces["$space_guid"]}
  space_name=$(echo "$space_info" | cut -d ',' -f 1)
  org_name=$(echo "$space_info" | cut -d ',' -f 2)

  # Retrieve apps in the space
  apps=$(cf curl "/v3/apps?space_guids=$space_guid&per_page=5000")
  app_names=$(echo "$apps" | jq -r '[.resources[].name] | join(", ")')

  # Retrieve services in the space
  services=$(cf curl "/v3/service_instances?space_guids=$space_guid&per_page=5000")
  service_count=$(echo "$services" | jq '.pagination.total_results')

  # Append result:
  echo "$space_name,$org_name,\"$app_names\",$service_count"
done
