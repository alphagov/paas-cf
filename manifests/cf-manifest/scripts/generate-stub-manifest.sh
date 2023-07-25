#!/bin/bash

# work out the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PAAS_CF_DIR="$( cd "${SCRIPT_DIR}/../../.." && pwd )"
export PAAS_CF_DIR
WORKDIR="${PAAS_CF_DIR}/manifests/shared/stubs"
export WORKDIR

cd "${WORKDIR}" || exit 1

ENV_SPECIFIC_BOSH_VARS_FILE=$PAAS_CF_DIR/manifests/cf-manifest/env-specific/default.yml
export ENV_SPECIFIC_BOSH_VARS_FILE
ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR=$PAAS_CF_DIR/manifests/cf-manifest/isolation-segments/default
export ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR

"${PAAS_CF_DIR}/manifests/cf-manifest/scripts/generate-manifest.sh"


