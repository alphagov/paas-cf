#!/bin/sh

set -eu

spruce merge \
  --prune meta \
  --prune secrets \
  --prune terraform_outputs \
  "$@"
