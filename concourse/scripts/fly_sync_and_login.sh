#!/bin/bash
set -euo pipefail

# Required env vars
# shellcheck disable=SC2086
: $CONCOURSE_URL \
  $CONCOURSE_WEB_USER \
  $CONCOURSE_WEB_PASSWORD \
  $FLY_CMD \
  $FLY_TARGET

fetch_fly() {
  echo "Downloading fly .."
  FLY_CMD_URL="${CONCOURSE_URL}/api/v1/cli?arch=amd64&platform=$(uname | tr '[:upper:]' '[:lower:]')"
  curl \
    --progress-bar \
    --location \
    --fail \
    --output "$FLY_CMD" \
    "$FLY_CMD_URL"
  chmod +x "$FLY_CMD"
}

fly_sync() {
  echo "Doing fly sync .."
  $FLY_CMD -t "${FLY_TARGET}" sync
}

fly_login() {
  echo "Doing fly login .."
  $FLY_CMD -t "${FLY_TARGET}" login --concourse-url "${CONCOURSE_URL}" -u "${CONCOURSE_WEB_USER}" -p "${CONCOURSE_WEB_PASSWORD}"
}

fly_is_runnable() {
  [ -x "${FLY_CMD}" ]
}

if fly_is_runnable; then
  if fly_login; then
    fly_sync
  else
    fetch_fly
    fly_login
  fi
else
  fetch_fly
  fly_login
fi
