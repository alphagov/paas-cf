#!/bin/sh

set -e
cd $(dirname $0)

if [ $# -gt 0 ]; then
  STUBS=$@
else
  STUBS=deployments/example-stubs/*.yml
fi

spruce merge \
  --prune meta \
  --prune secrets \
  --prune terraform_outputs \
  deployments/*.yml \
  deployments/aws/*.yml \
  $STUBS


