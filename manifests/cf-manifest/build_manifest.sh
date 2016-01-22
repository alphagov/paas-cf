#!/bin/sh

set -e

manifests_dir=${MANIFESTS_DIR:-"./"}
terraform_output_dir=${TERRAFORM_OUTPUT_DIR:-"${manifests_dir}/outputs/terraform"}
secrets=${SECRETS:-"${manifests_dir}/outputs/cf-secrets.yml"}
ssl_certs=${SSL_CERTS:-"${manifests_dir}/outputs/cf-ssl-certificates.yml"}

spruce merge \
  --prune meta --prune lamb_meta \
  --prune terraform_outputs \
  --prune secrets \
  "${manifests_dir}"/deployments/*.yml \
  "${manifests_dir}"/deployments/aws/*.yml \
  "${terraform_output_dir}"/*.yml \
  "${secrets}" \
  "${ssl_certs}"
