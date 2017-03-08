#!/bin/bash

set -eu
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

OUTPUT_FILE=$(mktemp -t bosh-cli.XXXXXX)
trap 'rm -f "${OUTPUT_FILE}"' EXIT

$FLY_CMD -t "${FLY_TARGET}" trigger-job -j create-cloudfoundry/cf-psql -w | tee "${OUTPUT_FILE}"

BUILD_NUMBER=$(awk '/started create-cloudfoundry\/cf-psql/ { print $3 }' "${OUTPUT_FILE}" | tr -d '#')

$FLY_CMD -t "${FLY_TARGET}" intercept -j create-cloudfoundry/cf-psql -b "${BUILD_NUMBER}" \
   -s run-cf-psql sh ./psql_adm.sh
