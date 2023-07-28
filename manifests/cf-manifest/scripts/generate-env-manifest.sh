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
    # check WORKDIR does not equal /
    if [[ "$WORKDIR" != "/" ]]; then
        rm -rf "$WORKDIR"
    fi
}
trap cleanup EXIT

STATE_BUCKET="gds-paas-${DEPLOY_ENV}-state"

cd "${WORKDIR}"
mkdir -p "${WORKDIR}/terraform-tfstate"
mkdir -p "${WORKDIR}/terraform-outputs"
# download state files from s3 bucket using aws command line
aws s3 cp "s3://${STATE_BUCKET}/vpc.tfstate" "$WORKDIR/terraform-tfstate/vpc.tfstate" --quiet
aws s3 cp "s3://${STATE_BUCKET}/psn.tfstate" "$WORKDIR/terraform-tfstate/psn.tfstate" --quiet
aws s3 cp "s3://${STATE_BUCKET}/bosh.tfstate" "$WORKDIR/terraform-tfstate/bosh.tfstate" --quiet
aws s3 cp "s3://${STATE_BUCKET}/cf.tfstate" "$WORKDIR/terraform-tfstate/cf.tfstate" --quiet
aws s3 cp "s3://${STATE_BUCKET}/azhc.tfstate" "$WORKDIR/terraform-tfstate/azhc.tfstate" --quiet
aws s3 cp "s3://${STATE_BUCKET}/bosh-secrets.yml" "$WORKDIR/bosh-secrets.yml" --quiet

for state in vpc bosh cf; do
    "${PAAS_CF_DIR}/concourse/scripts/extract_terraform_state_to_yaml.rb" \
        < "${WORKDIR}/terraform-tfstate/${state}.tfstate" \
        > "${WORKDIR}/terraform-outputs/${state}.yml"
    "${PAAS_CF_DIR}/concourse/scripts/extract_tf_vars_from_terraform_state.rb" \
        < "${WORKDIR}/terraform-tfstate/${state}.tfstate" \
        > "${WORKDIR}/terraform-outputs/${state}.tfvars.sh"
done

terraform output \
    -raw \
    "-state=${WORKDIR}/terraform-tfstate/psn.tfstate" \
    psn_security_group_seed_json > "${WORKDIR}/terraform-outputs/psn-peering.json"

mkdir -p "${WORKDIR}/vpc-peering-opsfile"
ruby "${PAAS_CF_DIR}/terraform/scripts/generate_vpc_peering_opsfile.rb" "${PAAS_CF_DIR}/terraform/${DEPLOY_ENV}.vpc_peering.json" \
    > "${WORKDIR}/vpc-peering-opsfile/vpc-peers.yml"

mkdir -p "${WORKDIR}/tenant-uaa-clients-opsfile"
ruby "${PAAS_CF_DIR}/manifests/cf-manifest/scripts/generate-tenant-uaa-client-ops-file.rb" \
    "${PAAS_CF_DIR}/manifests/cf-manifest/data/100-tenant-uaa-client-config.yml" \
    "${MAKEFILE_ENV_TARGET}" \
    > "${WORKDIR}/tenant-uaa-clients-opsfile/tenant-uaa-opsfile.yml"

mkdir -p "${WORKDIR}/ms-oauth-endpoints"
DISCOVERY_DOC=$(curl -s "https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration")

echo "${DISCOVERY_DOC}" | jq '.authorization_endpoint' --raw-output \
    > "${WORKDIR}/ms-oauth-endpoints/authorization_endpoint"

echo "${DISCOVERY_DOC}" | jq '.token_endpoint' --raw-output \
    > "${WORKDIR}/ms-oauth-endpoints/token_endpoint"

echo "${DISCOVERY_DOC}" | jq '.jwks_uri' --raw-output \
    > "${WORKDIR}/ms-oauth-endpoints/token_key_endpoint"

echo "${DISCOVERY_DOC}" | jq '.issuer' --raw-output \
    > "${WORKDIR}/ms-oauth-endpoints/issuer"

mkdir -p "${WORKDIR}/psn-peering-opsfile"
ruby "${PAAS_CF_DIR}/terraform/scripts/generate_vpc_peering_opsfile.rb" "${WORKDIR}/terraform-outputs/psn-peering.json" \
    > "${WORKDIR}/psn-peering-opsfile/psn-peers.yml"

mkdir -p "${WORKDIR}/paas-cf-cloud-config"
"${PAAS_CF_DIR}/manifests/cloud-config/scripts/generate-cloud-config.sh" > "${WORKDIR}/paas-cf-cloud-config/paas-cf-cloud-config.yml"

mkdir -p "${WORKDIR}/paas-cf-runtime-config"
"${PAAS_CF_DIR}/manifests/runtime-config/scripts/generate-runtime-config.sh" > "${WORKDIR}/paas-cf-runtime-config/paas-cf-runtime-config.yml"

ENV_SPECIFIC_BOSH_VARS_FILE="${PAAS_CF_DIR}/manifests/cf-manifest/env-specific/${ENV_SPECIFIC_BOSH_VARS_FILE}"
export ENV_SPECIFIC_BOSH_VARS_FILE
ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR="${PAAS_CF_DIR}/manifests/cf-manifest/isolation-segments/${ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR}"
export ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR

VCAP_PASSWORD=$(ruby -ryaml -e "puts YAML.load_file('$WORKDIR/bosh-secrets.yml')['secrets']['vcap_password']")
export VCAP_PASSWORD

cat <<EOF > environment-variables.yml
---
system_domain: ${SYSTEM_DNS_ZONE_NAME}
app_domain: ${APPS_DNS_ZONE_NAME}
environment: ${DEPLOY_ENV}
deployment_name: ${DEPLOY_ENV}
aws_account: ${AWS_ACCOUNT}
microsoft_oauth_auth_url: $(cat ms-oauth-endpoints/authorization_endpoint)
microsoft_oauth_token_url: $(cat ms-oauth-endpoints/token_endpoint)
microsoft_oauth_token_key_url: $(cat ms-oauth-endpoints/token_key_endpoint)
microsoft_oauth_issuer: $(cat ms-oauth-endpoints/issuer)
vcap_password: $VCAP_PASSWORD
EOF

"${PAAS_CF_DIR}/manifests/cf-manifest/scripts/generate-manifest.sh"
