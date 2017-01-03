#!/bin/bash -eu
set -o pipefail

JOB=$1
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PIPE='create-cloudfoundry'
TEMP="/tmp/concourse-run-job.${RANDOM}"
trap 'rm -f $TEMP' ERR

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh")
"${SCRIPT_DIR}/fly_sync_and_login.sh"
FLY="$FLY_CMD -t ${FLY_TARGET}"

# 2 steps prevent fly reading empty input in case step 1 fails
${FLY} get-pipeline -p ${PIPE} | "${SCRIPT_DIR}"/unbind_job.rb "${JOB}" >$TEMP
${FLY} set-pipeline -p ${PIPE} -c=$TEMP -n

${FLY} trigger-job -j "${PIPE}/${JOB}"
rm -f $TEMP
