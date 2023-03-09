#!/bin/bash
set -euo pipefail

# Required env vars
# shellcheck disable=SC2086
: $CONCOURSE_URL \
  $FLY_CMD \
  $FLY_TARGET

CONCOURSE_WEB_USER=${CONCOURSE_WEB_USER:-}
CONCOURSE_WEB_PASSWORD=${CONCOURSE_WEB_PASSWORD:-}

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
  if [ -n "$CONCOURSE_WEB_USER" ] && [ -n "$CONCOURSE_WEB_PASSWORD" ] ; then
    $FLY_CMD -t "${FLY_TARGET}" login --concourse-url "${CONCOURSE_URL}" -u "${CONCOURSE_WEB_USER}" -p "${CONCOURSE_WEB_PASSWORD}"
  else
    # shellcheck disable=SC2016
    echo '$CONCOURSE_WEB_USER and/or $CONCOURSE_WEB_PASSWORD not set - not attempting basic auth...'
    # Check if we are logged in, if we aren't then use the browser
    $FLY_CMD -t "${FLY_TARGET}" status || \
      $FLY_CMD -t "${FLY_TARGET}" login --concourse-url "${CONCOURSE_URL}"
  fi
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
