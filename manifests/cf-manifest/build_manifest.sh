#!/bin/sh

set -e

manifests_dir=${MANIFESTS_DIR:-"./"}
terraform_outputs=${TERRAFORM_OUTPUTS:-"${manifests_dir}/outputs/terraform-outputs.yml"}
secrets=${SECRETS:-"${manifests_dir}/outputs/cf-secrets.yml"}
ssl_certs=${SSL_CERTS:-"${manifests_dir}/outputs/cf-ssl-certificates.yml"}

spruce merge \
  --prune meta --prune lamb_meta \
  --prune terraform_outputs \
  --prune secrets \
  ${manifests_dir}/deployments/*.yml \
  ${manifests_dir}/deployments/aws/*.yml \
  ${terraform_outputs} \
  ${secrets} \
  ${ssl_certs} 
