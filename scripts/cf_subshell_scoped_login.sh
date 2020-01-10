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
    PASSCODE_URL="https://login.cloud.service.gov.uk/passcode"
    ;;
  prod-lon)
    API_URL="https://api.london.cloud.service.gov.uk"
    PASSCODE_URL="https://login.london.cloud.service.gov.uk/passcode"
    ;;
  stg-lon)
    API_URL="https://api.london.staging.cloudpipeline.digital"
    PASSCODE_URL="https://login.london.staging.cloudpipeline.digital/passcode"
    ;;
  *)
    echo "\"${TARGET}\" is not a named environment. Assuming this is a development environment." 1>&2
    API_URL="https://api.${TARGET}.dev.cloudpipeline.digital"
    PASSCODE_URL="https://login.${TARGET}.dev.cloudpipeline.digital/passcode"
    ;;
esac

TMPDIR=${TMPDIR:-/tmp}
CF_HOME=$(mktemp -d "${TMPDIR}/cf_home.XXXXXX")

cat <<EOF > "$CF_HOME/.bashrc"
__cf_target_env ()
{
  echo "$TARGET"
}

__cf_target_org ()
{
  jq -r '.OrganizationFields.Name' "${CF_HOME}/.cf/config.json"
}

__cf_target_space ()
{
  jq -r '.SpaceFields.Name' "${CF_HOME}/.cf/config.json"
}

source ~/.bashrc
EOF

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
open "${PASSCODE_URL}" && cf login --sso

echo
echo "You are now in a subshell with CF_HOME set to ${CF_HOME}"
echo "This will be cleaned up when this shell is closed."
echo
set -x
${SHELL:-bash} --rcfile "${CF_HOME}/.bashrc" -i
