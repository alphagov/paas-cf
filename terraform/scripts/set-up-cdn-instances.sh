#!/bin/sh

set -eu
TERRAFORM_ACTION=${1}
STATEFILE=cloudfront.tfstate

# Setup the working grounds.
PAAS_CF_DIR=$(pwd)
WORKING_DIR=$(mktemp -d terraform-cloudfront-distribution.XXXXXX)
trap 'rm -r "${PAAS_CF_DIR}/${WORKING_DIR}"' EXIT

cd "${WORKING_DIR}"

# Initialise Terraform with remote state.
terraform init \
  -backend=true \
  -backend-config="bucket=gds-paas-${DEPLOY_ENV}-state" \
  -backend-config="key=${STATEFILE}" \
  -backend-config="region=${AWS_DEFAULT_REGION}" \
  "${PAAS_CF_DIR}"/terraform/cloudfront

TERRAFORM_OPTS="
  -var-file=${PAAS_CF_DIR}/terraform/${AWS_ACCOUNT}.tfvars \
  -var env=${DEPLOY_ENV} \
  -var system_dns_zone_name=${SYSTEM_DNS_ZONE_NAME} \
  -var apps_dns_zone_name=${APPS_DNS_ZONE_NAME} \
  ${TERRAFORM_EXTRA_OPTS:-}
"
# Run the terraform action on the instances.
# shellcheck disable=SC2086
terraform "${TERRAFORM_ACTION}" \
  ${TERRAFORM_OPTS} \
  "${PAAS_CF_DIR}"/terraform/cloudfront
