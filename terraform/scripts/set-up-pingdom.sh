#!/bin/bash

set -eu

function help {
  cat <<EOF
Help

You need to install the terraform pingdom binary by adding the binary location to your path and copying or appending to your ~/.terraformrc file

export PATH=\$PWD/${TERRAFORM_PATH}${TERRAFORM_BINARY_DIR}:\$PATH

If you do not have a ~/.terraformrc file

cp ${TERRAFORM_PATH}/.terraformrc ~/.terraformrc
EOF
	exit 1
}

# Terraform Pingdom provider
TERRAFORM_PATH=terraform/providers
if [ "$(uname)" = "Darwin" ];
	then TERRAFORM_BINARY_DIR=/osx
	else TERRAFORM_BINARY_DIR=/linux-amd64
fi

# Get Pingdom credentials
export PASSWORD_STORE_DIR=~/.paas-pass
echo "Using password store: ${PASSWORD_STORE_DIR}"
PINGDOM_USER=$(pass pingdom.com/username)
PINGDOM_PASSWORD=$(pass pingdom.com/password)
PINGDOM_API_KEY=$(pass pingdom.com/api_key)
PINGDOM_ACCOUNT_EMAIL=$(pass pingdom.com/account_email)

# Check bucket for Terraform state file
cd terraform/pingdom
declare -r STATEFILE=pingdom-${MAKEFILE_ENV_TARGET}.tfstate
if ! aws s3 ls "s3://${DEPLOY_ENV}-state/${STATEFILE}" --summarize | grep -q "Total Objects: 0";
	then aws s3 cp "s3://${DEPLOY_ENV}-state/${STATEFILE}" "${STATEFILE}"
else
	echo "No previous ${STATEFILE} file found in s3://${DEPLOY_ENV}-state/. Assuming first run."
fi

# Run Terraform Pingdom Provider
set +e
terraform apply -state="${STATEFILE}" \
	-var "env=${MAKEFILE_ENV_TARGET}" \
	-var "pingdom_user=${PINGDOM_USER}" \
	-var "pingdom_password=${PINGDOM_PASSWORD}" \
	-var "pingdom_api_key=${PINGDOM_API_KEY}" \
	-var "pingdom_account_email=${PINGDOM_ACCOUNT_EMAIL}" \
	-var "apps_dns_zone_name=${APPS_DNS_ZONE_NAME}"
if [ "$?" -ne 0 ]; then help; fi
set -e

# Copy statefile back to bucket and remove local copy
aws s3 cp "${STATEFILE}" "s3://${DEPLOY_ENV}-state/${STATEFILE}"
rm -f "${STATEFILE}"
rm -f "${STATEFILE}".backup
