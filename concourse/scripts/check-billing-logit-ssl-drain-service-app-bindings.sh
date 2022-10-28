#!/usr/bin/env bash

# This script checks that bindings exist between the service billing-logit-ssl-drain and the billing apps. This is to ensure that the billing apps have been deployed successfully.

set -e -u -o pipefail

APP1_NAME='paas-billing-api'
APP2_NAME='paas-billing-collector'

APP1_GUID=$(cf curl "/v3/apps?names=${APP1_NAME}" | jq -r '.resources[].guid')
APP2_GUID=$(cf curl "/v3/apps?names=${APP2_NAME}" | jq -r '.resources[].guid')

SERVICE_INSTANCE_GUID=$(cf curl /v3/service_instances | jq -r '.resources[]|select(.name=="billing-logit-ssl-drain").guid')

SERVICE_CREDENTIAL_BINDINGS=$(cf curl "/v3/service_credential_bindings?service_instance_guids=${SERVICE_INSTANCE_GUID}")

SERVICE_CREDENTIAL_BINDINGS_COUNT=$(jq -r '.resources|length' <<< "${SERVICE_CREDENTIAL_BINDINGS}")
if [[ "${SERVICE_CREDENTIAL_BINDINGS_COUNT}" != "2" ]]; then
  echo "ERROR: expecting 2 service credential bindings. got: ${SERVICE_CREDENTIAL_BINDINGS_COUNT}"
  exit 1
fi

BIND1_GUID=$(jq -r '.resources[0].relationships.app.data.guid' <<< "${SERVICE_CREDENTIAL_BINDINGS}")
BIND1_STATE=$(jq -r '.resources[0].last_operation.state' <<< "${SERVICE_CREDENTIAL_BINDINGS}")
BIND1_TYPE=$(jq -r '.resources[0].last_operation.type' <<< "${SERVICE_CREDENTIAL_BINDINGS}")
BIND2_GUID=$(jq -r '.resources[1].relationships.app.data.guid' <<< "${SERVICE_CREDENTIAL_BINDINGS}")
BIND2_STATE=$(jq -r '.resources[1].last_operation.state' <<< "${SERVICE_CREDENTIAL_BINDINGS}")
BIND2_TYPE=$(jq -r '.resources[1].last_operation.type' <<< "${SERVICE_CREDENTIAL_BINDINGS}")

if ! [[ "${BIND1_GUID}" = "${APP1_GUID}" && "${BIND2_GUID}" = "${APP2_GUID}" || "${BIND1_GUID}" = "${APP2_GUID}" && "${BIND2_GUID}" = "${APP1_GUID}" ]]; then
  echo "ERROR: could not match app GUIDS to service binds"
  exit 1
fi

if ! [[ "${BIND1_STATE}" = "succeeded" && "${BIND1_TYPE}" = "create" && "${BIND2_STATE}" = "succeeded" && "${BIND2_TYPE}" = "create" ]]; then
  echo "ERROR: one or more bad bind states/types"
  exit 1
fi

echo "Checked binding of billing-logit-ssl-drain service to billing apps..."
