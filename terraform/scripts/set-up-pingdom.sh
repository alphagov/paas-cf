#!/bin/bash

set -eu
TERRAFORM_ACTION=${1}
VERSION=0.2.2
BINARY=terraform-provider-pingdom-tf-0.8.5-$(uname -s)-$(uname -m)
STATEFILE=pingdom-${AWS_ACCOUNT}.tfstate

# Get Pingdom credentials
export PASSWORD_STORE_DIR=~/.paas-pass
PINGDOM_USER=$(pass pingdom.com/username)
PINGDOM_PASSWORD=$(pass pingdom.com/password)
PINGDOM_API_KEY=$(pass pingdom.com/api_key)
PINGDOM_ACCOUNT_EMAIL=$(pass pingdom.com/account_email)

# Install Terraform plugin to temporary directory
PAAS_CF_DIR=$(pwd)
WORKING_DIR=$(mktemp -d terraform-pingdom.XXXXXX)
trap 'rm -r "${PAAS_CF_DIR}/${WORKING_DIR}"' EXIT

wget "https://github.com/alphagov/paas-terraform-provider-pingdom/releases/download/${VERSION}/${BINARY}" \
  -O "${WORKING_DIR}"/terraform-provider-pingdom
chmod +x "${WORKING_DIR}"/terraform-provider-pingdom

# Work in tmp dir to ensure there's no local state before we kick off terraform, it prioritises it
cd "${WORKING_DIR}"

# Configure Terraform remote state
terraform remote config \
    -backend=s3 \
    -backend-config="bucket=gds-paas-${DEPLOY_ENV}-state" \
    -backend-config="key=${STATEFILE}" \
    -backend-config="region=${AWS_DEFAULT_REGION}"

# Run Terraform Pingdom Provider
terraform "${TERRAFORM_ACTION}" \
	-var-file="${PAAS_CF_DIR}/terraform/${AWS_ACCOUNT}.tfvars" \
	-var "env=${DEPLOY_ENV}" \
	-var "pingdom_user=${PINGDOM_USER}" \
	-var "pingdom_password=${PINGDOM_PASSWORD}" \
	-var "pingdom_api_key=${PINGDOM_API_KEY}" \
	-var "pingdom_account_email=${PINGDOM_ACCOUNT_EMAIL}" \
	-var "apps_dns_zone_name=${APPS_DNS_ZONE_NAME}" \
  "${PAAS_CF_DIR}"/terraform/pingdom
