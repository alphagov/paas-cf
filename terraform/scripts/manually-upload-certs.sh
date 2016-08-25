#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR}
STATEFILE=cf-certs.tfstate

pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.key" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain_intermediate.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.key" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain_intermediate.crt" > /dev/null

# Ensure there's no local state before we kick off terraform, it prioritises it
rm -rf .terraform

WORKING_DIR=$(mktemp -d cf-certs.XXXXXX)
trap 'rm -r "${WORKING_DIR}"' EXIT

# Configure Terraform remote state
terraform remote config \
  -backend=s3 \
  -backend-config="bucket=${DEPLOY_ENV}-state" \
  -backend-config="key=${STATEFILE}" \
  -backend-config="region=${AWS_DEFAULT_REGION}"

terraform apply -var env="${DEPLOY_ENV}" \
  -var-file="terraform/${AWS_ACCOUNT}.tfvars" \
  -var system_domain_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.crt")" \
  -var system_domain_key="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.key")" \
  -var system_domain_intermediate_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain_intermediate.crt")" \
  -var apps_domain_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.crt")" \
  -var apps_domain_key="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.key")" \
  -var apps_domain_intermediate_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain_intermediate.crt")" \
  terraform/cf-certs

# Delete new local terraform state
rm -rf .terraform
