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

# Prepare output (header will be created later):
echo "Generating service plan type counts per space..."

declare -A orgs
declare -A spaces
declare -A space_service_plans  # Store service plan names per space
declare -A all_service_plans  # To track unique service plan types
declare -A space_org_names  # Store organization names per space

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

    spaces_query=$(cf curl "/v3/spaces?organization_guids=$org_guid&per_page=5000" | jq -rc '.resources[] | {guid: .guid, name: .name}')
    while IFS= read -r space; do
        space_guid=$(echo "$space" | jq -r '.guid')
        space_name=$(echo "$space" | jq -r '.name')

        if [[ -z "$space_guid" ]]; then
            echo "Warning: space_guid is empty for space $space_name in org $org_name" >&2
            continue
        fi

        spaces["$space_guid"]="$space_name"
        space_service_plans["$space_guid"]=""  # Initialize empty list of service plans for this space
        space_org_names["$space_guid"]="$org_name"
    done <<< "$spaces_query"
done

# Gather service plan names for each space
for space_guid in "${!spaces[@]}"; do
    services=$(cf curl "/v3/service_instances?space_guids=$space_guid&per_page=5000")
    service_plan_guids=$(echo "$services" | jq -r '.resources[].relationships.service_plan.data.guid')

    for service_plan_guid in $service_plan_guids; do
        if [[ -n "$service_plan_guid" ]]; then
          # Change this to service_plans:
            plan_name=$(cf curl "/v3/service_plans/$service_plan_guid" | jq -r '.name')
            if [[ "$plan_name" == null ]]; then
#                echo "Warning: Plan name for GUID $service_plan_guid is null or empty"
                continue  # Skip this service plan if name is empty
            fi
            if [[ -n "$plan_name" ]]; then
                # Store service plan name for the current space
                space_service_plans["$space_guid"]+="$plan_name "
                all_service_plans["$plan_name"]=1  # Track all unique service plan names
            fi
        fi
    done
done

# Create CSV header based on unique service plan types
header="space_name,orgs"
for service_plan in "${!all_service_plans[@]}"; do
    header+=",$service_plan"
done
echo "$header"
# Iterate through stored service plans and count them for each space
for space_guid in "${!spaces[@]}"; do
    space_name=${spaces["$space_guid"]}
    org_name=${space_org_names["$space_guid"]}

    # Initialize count array for this space
    declare -A service_plan_counts
    for plan in "${!all_service_plans[@]}"; do
        service_plan_counts["$plan"]=0
    done
#
    # Count occurrences of each service plan in this space
    for plan_name in ${space_service_plans["$space_guid"]}; do
      service_plan_counts["$plan_name"]=$(( ${service_plan_counts["$plan_name"]:-0} + 1 ))
    done
#
    # Build the row output for the current space
    row="$space_name,$org_name"
    for plan in "${!all_service_plans[@]}"; do
        row+=","${service_plan_counts["$plan"]}
    done
    echo "$row"
done
