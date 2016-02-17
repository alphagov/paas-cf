#!/bin/bash

set -eu
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

env=${1-${DEPLOY_ENV-}}
if [ -z "${env}" ]; then
  echo "Must specify DEPLOY_ENV as \$1 or environment variable"
  exit 1
fi

FLY_TARGET=${FLY_TARGET:-$env}
FLY_CMD=${FLY_CMD:-fly}

OUTPUT_FILE=$(mktemp -t bosh-cli.XXXXXX)
trap 'rm -f "${OUTPUT_FILE}"' EXIT

$FLY_CMD -t "${FLY_TARGET}" \
  execute \
  --inputs-from=deploy-cloudfoundry/deploy \
  --config="${SCRIPT_DIR}/../pipelines/bosh-cli/bosh-cli.yml" \
  | tee "${OUTPUT_FILE}"

BUILD_NUMBER=$(awk '/executing build/ { print $3 }' "${OUTPUT_FILE}")

$FLY_CMD -t "${FLY_TARGET}" \
  intercept \
  --build="${BUILD_NUMBER}"\
  --step=one-off \
  sh
