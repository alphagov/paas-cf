#!/bin/bash

set -eu
TERRAFORM_ACTION=${1}
STATEFILE=cloudfront.tfstate

# Setup the working grounds.
PAAS_CF_DIR=$(pwd)
WORKING_DIR=$(mktemp -d terraform-cloudfront-distribution.XXXXXX)
trap 'rm -r "${PAAS_CF_DIR}/${WORKING_DIR}"' EXIT

cd "${WORKING_DIR}"

terraform get "${PAAS_CF_DIR}/terraform/cloudfront"

# Configure Terraform remote state.
terraform remote config \
  -backend=s3 \
  -backend-config="bucket=gds-paas-${DEPLOY_ENV}-state" \
  -backend-config="key=${STATEFILE}" \
  -backend-config="region=${AWS_DEFAULT_REGION}"

# Run the terraform action on the instances.
terraform "${TERRAFORM_ACTION}" \
  -var-file="${PAAS_CF_DIR}/terraform/${AWS_ACCOUNT}.tfvars" \
  -var "env=${DEPLOY_ENV}" \
  -var "system_dns_zone_name=${SYSTEM_DNS_ZONE_NAME}" \
  "${PAAS_CF_DIR}"/terraform/cloudfront
