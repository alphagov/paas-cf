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

BOSH_CA_CERT="$(cat "${WORKDIR}/bosh-CA.crt")"
BOSH_CA_CERT="$(awk -v ORS='\\n' '1' <(printenv BOSH_CA_CERT | tr -d '\r'))"
export BOSH_CA_CERT

"${PAAS_CF_DIR}/manifests/prometheus/scripts/generate-manifest.sh"
