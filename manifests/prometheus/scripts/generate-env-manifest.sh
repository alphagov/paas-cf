#!/usr/bin/env bash

set -euo pipefail

# work out the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PAAS_CF_DIR="$( cd "${SCRIPT_DIR}/../../.." && pwd )"
export PAAS_CF_DIR

# create temporary directory
WORKDIR=$(mktemp -d)

# clean up temporary directory on exit
function cleanup {
    if [[ "$WORKDIR" != "/" ]]; then
        rm -r "$WORKDIR"
    fi
}
trap cleanup EXIT

STATE_BUCKET="gds-paas-${DEPLOY_ENV}-state"

cd "${WORKDIR}"

credhub find -n /concourse/main/bosh-exporter-password > /dev/null 2>&1 || (echo "You need to connect to credhub." && exit 1)

mkdir -p "${WORKDIR}/terraform-tfstate"
mkdir -p "${WORKDIR}/paas-trusted-people"
mkdir -p "${WORKDIR}/terraform-outputs"
aws s3 cp "s3://${STATE_BUCKET}/cf.tfstate" "${WORKDIR}/terraform-tfstate/cf.tfstate" --quiet
aws s3 cp "s3://${STATE_BUCKET}/paas-trusted-people/users.yml" "${WORKDIR}/paas-trusted-people/users.yml" --quiet
aws s3 cp "s3://${STATE_BUCKET}/bosh-CA.crt" "${WORKDIR}/bosh-CA.crt" --quiet
aws s3 cp "s3://${STATE_BUCKET}/bosh-secrets.yml" "${WORKDIR}/bosh-secrets.yml" --quiet

"${PAAS_CF_DIR}/concourse/scripts/extract_terraform_state_to_yaml.rb" \
    < "${WORKDIR}/terraform-tfstate/cf.tfstate" \
    > "${WORKDIR}/terraform-outputs/cf.yml"

BOSH_URL="bosh.${SYSTEM_DNS_ZONE_NAME}"
export BOSH_URL

VCAP_PASSWORD=$(ruby -ryaml -e "puts YAML.load_file('$WORKDIR/bosh-secrets.yml')['secrets']['vcap_password']")
export VCAP_PASSWORD

# All these variables are scoped into the wrong part of credhub. Why? who knows. This means
# this script needs access to credhub to extract them. Wouldn't it be lovely if they were
# scoped right, then we could just refer to them as ((variable)) in the manifest.

BOSH_EXPORTER_PASSWORD="$(credhub get -q -n /concourse/main/bosh-exporter-password)"
export BOSH_EXPORTER_PASSWORD
GRAFANA_AUTH_GOOGLE_CLIENT_ID="$(credhub get -q -n /concourse/main/create-cloudfoundry/grafana_auth_google_client_id)"
export GRAFANA_AUTH_GOOGLE_CLIENT_ID
GRAFANA_AUTH_GOOGLE_CLIENT_SECRET="$(credhub get -q -n /concourse/main/create-cloudfoundry/grafana_auth_google_client_secret)"
export GRAFANA_AUTH_GOOGLE_CLIENT_SECRET
UAA_CLIENTS_CF_EXPORTER_SECRET="$(credhub get -q -n /concourse/main/create-cloudfoundry/uaa_clients_cf_exporter_secret)"
export UAA_CLIENTS_CF_EXPORTER_SECRET
UAA_CLIENTS_FIREHOSE_EXPORTER_SECRET="$(credhub get -q -n /concourse/main/create-cloudfoundry/uaa_clients_firehose_exporter_secret)"
export UAA_CLIENTS_FIREHOSE_EXPORTER_SECRET

BOSH_CA_CERT="$(cat "${WORKDIR}/bosh-CA.crt")"
BOSH_CA_CERT="$(awk -v ORS='\\n' '1' <(printenv BOSH_CA_CERT | tr -d '\r'))"
export BOSH_CA_CERT

"${PAAS_CF_DIR}/manifests/prometheus/scripts/generate-manifest.sh"
