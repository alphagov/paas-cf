#!/bin/bash -e
SCRIPT_DIR=$(cd "$(dirname $_)" && pwd)
BOSH_PW=${BOSH_PW:-"abc"}
BOSH=$(which bosh)

if [ -z "${DEPLOYER_CONCOURSE}" ]; then
  echo "Must provide DEPLOYER_CONCOURSE ip as env. var"
else
  bosh() {
  if [[ $1 == "ssh" ]]; then
       shift
       $BOSH ssh --default_password "${BOSH_PW}" \
                 --gateway_host "${DEPLOYER_CONCOURSE}" \
                 --gateway_user vcap \
                 --gateway_identity_file "${SCRIPT_DIR}"/session/id_rsa \
                 "$@"
  else
       $BOSH "$@"
  fi
  }
fi
