#!/bin/sh

set -e

manifests_dir=${MANIFESTS_DIR:-"./"}
terraform_output_dir=${TERRAFORM_OUTPUT_DIR:-"${manifests_dir}/outputs/terraform"}
secrets=${SECRETS:-"${manifests_dir}/outputs/cf-secrets.yml"}
ssl_certs=${SSL_CERTS:-"${manifests_dir}/outputs/cf-ssl-certificates.yml"}
ssl_certs_dir=${SSL_CERTS_DIR:-}
uaa_jwt_verification_key=${UAA_JWT_VERIFICATION_KEY:-}

spruce merge \
  --prune meta --prune lamb_meta \
  --prune terraform_outputs \
  --prune secrets \
  "${manifests_dir}"/deployments/*.yml \
  "${manifests_dir}"/deployments/aws/*.yml \
  "${terraform_output_dir}"/*.yml \
  "${secrets}" \
  "${ssl_certs}" \
  ${ssl_certs_dir:+"${ssl_certs_dir}"/*.yml} \
  ${uaa_jwt_verification_key:+"${uaa_jwt_verification_key}"}
