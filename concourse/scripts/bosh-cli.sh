#!/bin/bash

set -eu
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh" "$@")

OUTPUT_FILE=$(mktemp -t bosh-cli.XXXXXX)
trap 'rm -f "${OUTPUT_FILE}"' EXIT

$FLY_CMD -t "${FLY_TARGET}" \
  execute \
  --inputs-from=create-bosh-cloudfoundry/cf-deploy \
  --config="${SCRIPT_DIR}/../pipelines/bosh-cli/bosh-cli.yml" \
  | tee "${OUTPUT_FILE}"

BUILD_NUMBER=$(awk '/executing build/ { print $3 }' "${OUTPUT_FILE}")

$FLY_CMD -t "${FLY_TARGET}" \
  intercept \
  --build="${BUILD_NUMBER}"\
  --step=one-off \
  sh
