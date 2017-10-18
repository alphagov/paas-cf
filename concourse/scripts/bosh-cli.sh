#!/bin/bash

set -eu
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

BUILD_NUMBER=$($FLY_CMD -t "${FLY_TARGET}" trigger-job -j create-cloudfoundry/bosh-cli | \
	awk '/started create-cloudfoundry\/bosh-cli/ { print $3 }' | \
	tr -d '#')

while $FLY_CMD -t "${FLY_TARGET}" builds -j create-cloudfoundry/bosh-cli | awk '{print $3 $4}' | grep "${BUILD_NUMBER}pending" >/dev/null; do
	echo "waiting for create-cloudfoundry/bosh-cli container (${BUILD_NUMBER}) to start..."
	sleep 2
done
sleep 8 # required since even after status is 'started' it takes a few seconds

echo "hijacking create-cloudfoundry/bosh-cli container (${BUILD_NUMBER})..."
trap '$FLY_CMD -t "${FLY_TARGET}" abort-build -j create-cloudfoundry/bosh-cli -b "${BUILD_NUMBER}"' EXIT
$FLY_CMD -t "${FLY_TARGET}" intercept -j create-cloudfoundry/bosh-cli -b "${BUILD_NUMBER}" \
   -s run-bosh-cli "${@:-ash}"
