#!/bin/bash
set -euo pipefail

# Required env vars
# CONCOURSE_URL
# CONCOURSE_ATC_USER
# CONCOURSE_ATC_PASSWORD
# FLY_CMD
# FLY_TARGET

if [ ! -x "$FLY_CMD" ]; then
  FLY_CMD_URL="${CONCOURSE_URL}/api/v1/cli?arch=amd64&platform=$(uname | tr '[:upper:]' '[:lower:]')"
  echo "Downloading fly command..."
  curl "$FLY_CMD_URL" -L -f -k -o "$FLY_CMD" -u "${CONCOURSE_ATC_USER}:${CONCOURSE_ATC_PASSWORD}"
  chmod +x "$FLY_CMD"
fi

echo "Doing fly login & sync"
echo -e "${CONCOURSE_ATC_USER}\n${CONCOURSE_ATC_PASSWORD}" | \
  $FLY_CMD -t "${FLY_TARGET}" login -k --concourse-url "${CONCOURSE_URL}"

$FLY_CMD -t "${FLY_TARGET}" sync
