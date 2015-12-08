#!/bin/sh

set -e
cd $(dirname $0)

terraform_outputs=${TERRAFORM_OUTPUTS:-"outputs/terraform-outputs.yml"}
secrets=${SECRETS:-"outputs/cf-secrets.yml"}
ssl_certs=${SSL_CERTS:-"outputs/cf-ssl-certificates.yml"}

spruce merge \
  --prune meta --prune lamb_meta \
  --prune terraform_outputs \
  --prune secrets \
  deployments/*.yml \
  deployments/aws/*.yml \
  ${terraform_outputs} \
  ${secrets} \
  ${ssl_certs}
