#!/bin/bash
set -euo pipefail

# Required env vars
# CONCOURSE_URL
# CONCOURSE_ATC_USER
# CONCOURSE_ATC_PASSWORD
# FLY_CMD
# FLY_TARGET

FLY_CMD_URL="${CONCOURSE_URL}/api/v1/cli?arch=amd64&platform=$(uname | tr '[:upper:]' '[:lower:]')"
echo "Downloading fly command..."
curl "$FLY_CMD_URL" -# -L -f -k -z "$FLY_CMD" -o "$FLY_CMD" -u "${CONCOURSE_ATC_USER}:${CONCOURSE_ATC_PASSWORD}"
chmod +x "$FLY_CMD"

echo "Doing fly login"
echo -e "${CONCOURSE_ATC_USER}\n${CONCOURSE_ATC_PASSWORD}" | \
  $FLY_CMD -t "${FLY_TARGET}" login -k --concourse-url "${CONCOURSE_URL}"

echo "Doing fly sync"
  $FLY_CMD -t "${FLY_TARGET}" sync
