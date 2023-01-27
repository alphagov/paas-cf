#!/usr/bin/env bash

set -euo pipefail

ORG_TO_SUSPEND=${1:-}

SUSPENDED="true"

function usage() {
  local error_message=${1:-}
  if [ -n "${error_message}" ]; then
    echo -e "ERROR: ${error_message}\n"
  fi
  echo "Usage: $0 <org-name>"
  echo "If you want to unsuspend an org, set the UNSUSPEND env var to 'true'"
  exit 1
}

if [ -z "${ORG_TO_SUSPEND}" ]; then
  usage "You must specify an org name"
fi

verb="Suspending"

case "${UNSUSPEND:-false}" in
  "true" | "1")
    SUSPENDED="false"
    verb="Unsuspending"
    ;;
  "false" | "0")
    SUSPENDED="true"
    ;;
  *)
    usage "UNSUSPEND must be set to 'true' or 'false'"
    ;;
esac

ORG_GUID=$(cf org "${ORG_TO_SUSPEND}" --guid)
ENDPOINT_URL=$(cf curl / | jq -r .links.self.href)

echo "${verb} org ${ORG_TO_SUSPEND} (${ORG_GUID}) at ${ENDPOINT_URL}"
read -p "Is this correct? [yN] " -n 1 -r
echo
if [[ ! ${REPLY:-N} =~ ^[Yy]$ ]]; then
  echo "Aborting"
  exit 1
fi
if which jq >/dev/null; then
  cf curl -X PATCH -d '{"suspended": '"${SUSPENDED}"'}' "/v3/organizations/${ORG_GUID}" | jq .
else
  cf curl -X PATCH -d '{"suspended": '"${SUSPENDED}"'}' "/v3/organizations/${ORG_GUID}"
fi
