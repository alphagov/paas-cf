#!/bin/bash
#
# Required variables are:
# - DEPLOY_ENV
# - AWS_ACCOUNT

set -u
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

case "${1:-}" in
  pin)
    echo "Pausing pipeline kick-off."
    action=pin
    ;;
  unpin)
    echo "Unpausing pipeline kick-off."
    action=unpin
    ;;
  *)
    echo "Usage $0 <pin|unpin>"
    exit 1
    ;;
esac

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh")
"${SCRIPT_DIR}/fly_sync_and_login.sh"
FLY="$FLY_CMD -t ${FLY_TARGET}"

${FLY} "${action}-resource" -r "deployment-kick-off/deployment-timer"
