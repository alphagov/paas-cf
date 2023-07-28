#!/bin/bash

# work out the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PAAS_CF_DIR="$( cd "${SCRIPT_DIR}/../../.." && pwd )"
export PAAS_CF_DIR
WORKDIR=$PAAS_CF_DIR/manifests/shared/stubs
export WORKDIR

cd "${WORKDIR}" || exit 1

AWS_ACCOUNT="dev"
export AWS_ACCOUNT
SYSTEM_DNS_ZONE_NAME="system.example.com"
export SYSTEM_DNS_ZONE_NAME
APPS_DNS_ZONE_NAME="apps.example.com"
export APPS_DNS_ZONE_NAME
DEPLOY_ENV="test"
export DEPLOY_ENV
BOSH_CA_CERT="bosh-CA.crt"
export BOSH_CA_CERT
VCAP_PASSWORD="vcap-password"
export VCAP_PASSWORD

"${PAAS_CF_DIR}/manifests/app-autoscaler/scripts/generate-manifest.sh"
