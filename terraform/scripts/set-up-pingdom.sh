#!/bin/bash

set -eu
VERSION=0.2.1
BINARY=terraform-provider-pingdom-$(uname -s)-$(uname -m)
STATEFILE=pingdom-${MAKEFILE_ENV_TARGET}.tfstate

# Get Pingdom credentials
export PASSWORD_STORE_DIR=~/.paas-pass
PINGDOM_USER=$(pass pingdom.com/username)
PINGDOM_PASSWORD=$(pass pingdom.com/password)
PINGDOM_API_KEY=$(pass pingdom.com/api_key)
PINGDOM_ACCOUNT_EMAIL=$(pass pingdom.com/account_email)

# Install Terraform plugin to temporary directory
mkdir -p /tmp/terraform-pingdom
wget "https://github.com/alphagov/paas-terraform-provider-pingdom/releases/download/${VERSION}/${BINARY}" \
  -O /tmp/terraform-pingdom/terraform-provider-pingdom
chmod +x /tmp/terraform-pingdom/terraform-provider-pingdom
cp terraform/providers/.terraformrc /tmp/terraform-pingdom/

# Configure Terraform remote state
terraform remote config \
    -backend=s3 \
    -backend-config="bucket=${DEPLOY_ENV}-state" \
    -backend-config="key=${STATEFILE}" \
    -backend-config="region=${AWS_DEFAULT_REGION}"

# Run Terraform Pingdom Provider. We change $HOME so Terraform can find terraformrc
HOME=/tmp/terraform-pingdom \
terraform apply \
	-var "env=${MAKEFILE_ENV_TARGET}" \
	-var "contact_ids=${PINGDOM_CONTACT_IDS}" \
	-var "pingdom_user=${PINGDOM_USER}" \
	-var "pingdom_password=${PINGDOM_PASSWORD}" \
	-var "pingdom_api_key=${PINGDOM_API_KEY}" \
	-var "pingdom_account_email=${PINGDOM_ACCOUNT_EMAIL}" \
	-var "apps_dns_zone_name=${APPS_DNS_ZONE_NAME}" \
  terraform/pingdom

# Delete temporary directory
rm -rf /tmp/terraform-pingdom
