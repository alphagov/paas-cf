#!/bin/sh

SCRIPT=$0
RDS_INSTANCE_ID=$1

if [ -z "${RDS_INSTANCE_ID}" ] || [ "${RDS_INSTANCE_ID}" = "help" ]; then
  cat <<EOF
Usage:

  $SCRIPT <guid>

$SCRIPT will execute number of calls to CloudFoundry API in order to learn what
the instance is and who does it belong to.

The data it will return are:

 * Organisation
 * Space
 * Instance
 * Managers

Requirements:

 * You must login with the cf client with an "admin" user.

Where:
  <guid> Instance GUID obtained from metrics or Kibana.

EOF
  exit 1
fi

printf "Organisation:\\t%s\\n" "$(cf curl "$(cf curl "$(cf curl /v2/service_instances/"${RDS_INSTANCE_ID}" | jq -r '.entity.space_url')" | jq -r '.entity.organization_url')" | jq -r '.entity.name')"
printf "Space:\\t\\t%s\\n" "$(cf curl "$(cf curl /v2/service_instances/"${RDS_INSTANCE_ID}" | jq -r '.entity.space_url')" | jq -r '.entity.name')"
printf "Instance:\\t%s\\n" "$(cf curl /v2/service_instances/"${RDS_INSTANCE_ID}" | jq -r '.entity.name')"
printf "Managers:\\t\\n"
cf curl "$(cf curl "$(cf curl /v2/service_instances/"${RDS_INSTANCE_ID}" | jq -r '.entity.space_url')" | jq -r '.entity.organization_url')/managers" | jq -r '.resources[].entity.username'
