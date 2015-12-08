#!/bin/sh

set -e
cd $(dirname $0)

terraform_outputs=${TERRAFORM_OUTPUTS:-"outputs/terraform-outputs.yml"}

spruce merge \
  --prune meta --prune lamb_meta \
  --prune terraform_outputs \
  deployments/*.yml \
  deployments/aws/*.yml \
  ${terraform_outputs}
