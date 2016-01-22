#!/bin/sh

set -eu
cd "$(dirname "$0")"

spruce merge \
  --prune meta \
  --prune secrets \
  --prune terraform_outputs \
  deployments/*.yml \
  deployments/aws/*.yml \
  "${BOSH_SECRETS}" \
  "${BOSH_TERRAFORM_OUTPUTS}" \
  "${VPC_TERRAFORM_OUTPUTS}"
