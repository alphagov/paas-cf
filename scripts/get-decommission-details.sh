#!/usr/bin/env bash

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

if [ -n "$optional_orgs" ]; then
  echo "Filtering to a comma separated list of orgs: $optional_orgs"
fi

# Prepare output:
echo "organization_name,running_app_count,non_running_app_count,service_count,owner,ready_for_decommission,suspended"

declare -A orgs
declare -A owners

# Get organizations:
if [ -n "$optional_orgs" ]; then
  orgs_query=$(cf curl "/v3/organizations?names=$optional_orgs&per_page=5000&order_by=name" | jq -rc '.resources[] | {guid: .guid, name: .name, owner: .metadata.annotations.owner}')
else
  orgs_query=$(cf curl "/v3/organizations?per_page=5000&order_by=name" | jq -rc '.resources[] | {guid: .guid, name: .name, owner: .metadata.annotations.owner}')
fi

while IFS= read -r line; do
  org_guid=$(echo "$line" | jq -r '.guid')
  org_name=$(echo "$line" | jq -r '.name')
  org_owner=$(echo "$line" | jq -r '.owner')
  orgs["$org_guid"]="$org_name"
  owners["$org_guid"]="$org_owner"
done <<< "$orgs_query"

# For each unique org:
for org_guid in "${!orgs[@]}"; do
  org_name=${orgs["$org_guid"]}
  org_owner=${owners["$org_guid"]}

  if [[ $org_name == ASATS* ]] || [[ $org_name == SMOKE* ]]  || [[ $org_name == ACC* ]] || [[ $org_name == AIVEN* ]] || [[ $org_name == BACC* ]] || [[ $org_owner == Platform ]]; then
    continue
  fi

  if [[ -z "$org_name" ]]; then
    null_orgs+=("$org_guid")
    continue
  fi

  suspended=$(cf curl "/v3/organizations/$org_guid" | jq -r '.suspended')
  apps=$(cf curl "/v3/apps?organization_guids=$org_guid&per_page=5000")

  # Count running and non-running apps:
  running_app_count=$(echo "$apps" | jq '[ .resources[] | select(.state == "STARTED") ] | length')
  non_running_app_count=$(echo "$apps" | jq '[ .resources[] | select(.state != "STARTED") ] | length')

  # ready for decommissioning if both counts are zero
  if [[ $running_app_count == 0 ]] && [[ $non_running_app_count == 0 ]]; then
    ready_for_decommission=yes
  else
    ready_for_decommission=no
  fi

  running_services=$(cf curl "/v3/service_instances?organization_guids=$org_guid&per_page=5000" | jq '.pagination.total_results')

  # ready for decommissioning if both counts are zero
  if [[ $running_services != 0 ]]; then
    if [[ $ready_for_decommission == yes ]]; then
      ready_for_decommission=no
    fi
  fi

  # Append result:
  echo "$org_name,$running_app_count,$non_running_app_count,$running_services,\"$org_owner\",$ready_for_decommission,$suspended"
done
