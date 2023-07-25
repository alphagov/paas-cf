#!/bin/bash

# work out the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PAAS_CF_DIR="$( cd "${SCRIPT_DIR}/../../.." && pwd )"
export PAAS_CF_DIR
WORKDIR=$PAAS_CF_DIR/manifests/shared/stubs
export WORKDIR

cd "${WORKDIR}" || exit 1

export DEPLOY_ENV="dev"
export BOSH_URL="https://bosh.local"
export AWS_ACCOUNT="dev"
export AWS_REGION="fake-1"
export SYSTEM_DNS_ZONE_NAME="system.example.com"
export APPS_DNS_ZONE_NAME="apps.example.com"
export DEPLOY_ENV="test"
export BOSH_URL="https://bosh.example.com:25555"
export GRAFANA_AUTH_GOOGLE_CLIENT_ID="google-client-id"
export GRAFANA_AUTH_GOOGLE_CLIENT_SECRET="google-client-secret"
export UAA_CLIENTS_CF_EXPORTER_SECRET="uaa_clients_cf_exporter_secret"
export UAA_CLIENTS_FIREHOSE_EXPORTER_SECRET="uaa_clients_firehose_exporter_secret"
export BOSH_CA_CERT="bosh-CA.crt"
export BOSH_EXPORTER_PASSWORD="bosh-exporter-password"
export VCAP_PASSWORD="vcap-password"

export VARS_STORE="${WORKDIR}/cf-vars-store.yml"
export ENV_SPECIFIC_BOSH_VARS_FILE="default.yml"

"${PAAS_CF_DIR}/manifests/prometheus/scripts/generate-manifest.sh"
