#!/bin/sh

set -eu

if [ $# -lt 1 ]; then
  echo "Usage $0 <target>" 1>&2
  exit 1
fi

TARGET=${1}

case $TARGET in
  prod)
    API_URL="https://api.cloud.service.gov.uk"
    ;;
  prod-lon)
    API_URL="https://api.london.cloud.service.gov.uk"
    ;;
  stg-lon)
    API_URL="https://api.london.staging.cloudpipeline.digital"
    ;;
  *)
    echo "\"${TARGET}\" is not a named environment. Assuming this is a development environment." 1>&2
    API_URL="https://api.${TARGET}.dev.cloudpipeline.digital"
    ;;
esac

TMPDIR=${TMPDIR:-/tmp}
CF_HOME=$(mktemp -d "${TMPDIR}/cf_home.XXXXXX")
cleanup() {
  echo "Cleaning up temporary CF_HOME..."
  cf logout || true
  rm -r "${CF_HOME}"
}
trap 'cleanup' EXIT

mkdir -p "${HOME}/.cf/plugins" "${CF_HOME}/.cf"
ln -s "${HOME}/.cf/plugins" "${CF_HOME}/.cf/plugins"

export CF_HOME
export CF_SUBSHELL_TARGET=$TARGET

cf api "${API_URL}"
cf login --sso

echo
echo "You are now in a subshell with CF_HOME set to ${CF_HOME}"
echo "This will be cleaned up when this shell is closed."
echo
${SHELL:-bash} -il
