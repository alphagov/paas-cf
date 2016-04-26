#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${CERT_PASSWORD_STORE_DIR}

pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.key" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.crt" > /dev/null
pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.key" > /dev/null

WORKING_DIR=$(mktemp -d cf-certs.XXXXXX)

if ! aws s3 ls "s3://${DEPLOY_ENV}-state/cf-certs.tfstate" --summarize | grep -q "Total Objects: 0"; then
  aws s3 cp "s3://${DEPLOY_ENV}-state/cf-certs.tfstate" "${WORKING_DIR}/cf-certs.tfstate"
else
  echo "No previous cf-certs.tfstate file found in s3://${DEPLOY_ENV}-state/. Assuming first run."
fi

terraform apply -var env="${DEPLOY_ENV}" \
  -var-file="terraform/${AWS_ACCOUNT}.tfvars" \
  -state="${WORKING_DIR}/cf-certs.tfstate" \
  -var system_domain_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.crt")" \
  -var system_domain_key="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/system_domain.key")" \
  -var apps_domain_crt="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.crt")" \
  -var apps_domain_key="$(pass "certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/apps_domain.key")" \
  terraform/cf-certs

aws s3 cp "${WORKING_DIR}/cf-certs.tfstate" "s3://${DEPLOY_ENV}-state/cf-certs.tfstate"
rm -r "${WORKING_DIR}"
