#!/bin/sh

set -eu

TERRAFORM_ACTION=${1}
export PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR}
STATEFILE=cf-certs.tfstate

pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.key" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain_intermediate.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.key" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain_intermediate.crt" > /dev/null

PAAS_CF_DIR=$(pwd)
WORKING_DIR=$(mktemp -d cf-certs.XXXXXX)
BACKEND_CONFIG="${PAAS_CF_DIR}"/terraform/cf-certs/backends.tf
cat > "${BACKEND_CONFIG}" <<EOF
terraform {
  backend "s3" {}
}
EOF

cleanup() {
  rm "${BACKEND_CONFIG}"
  rm -r "${PAAS_CF_DIR:?}/${WORKING_DIR}"
}
trap 'cleanup' EXIT

# Work in tmp dir to ensure there's no local state before we kick off terraform, it prioritises it
cd "${WORKING_DIR}"

# Configure Terraform remote state
terraform init \
  -backend=true \
  -backend-config="bucket=gds-paas-${DEPLOY_ENV}-state" \
  -backend-config="key=${STATEFILE}" \
  -backend-config="region=${AWS_DEFAULT_REGION}" \
  "${PAAS_CF_DIR}"/terraform/cf-certs

terraform "${TERRAFORM_ACTION}" -var env="${DEPLOY_ENV}" \
  -var-file="${PAAS_CF_DIR}/terraform/${AWS_ACCOUNT}.tfvars" \
  -var system_domain_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.crt")" \
  -var system_domain_key="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.key")" \
  -var system_domain_intermediate_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain_intermediate.crt")" \
  -var apps_domain_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.crt")" \
  -var apps_domain_key="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.key")" \
  -var apps_domain_intermediate_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain_intermediate.crt")" \
  "${PAAS_CF_DIR}"/terraform/cf-certs
