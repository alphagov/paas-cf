#!/bin/sh

set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

spruce merge \
  --prune meta \
  --prune secrets \
  --prune terraform_outputs \
  "${SCRIPT_DIR}"/concourse-base.yml \
  "$@"

