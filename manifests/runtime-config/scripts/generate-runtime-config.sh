#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
WORKDIR=${WORKDIR:-.}

opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/runtime-config/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

# shellcheck disable=SC2086
bosh interpolate \
  --vars-file="${PAAS_CF_DIR}/manifests/variables.yml" \
  --var bosh_director_name="${DEPLOY_ENV}" \
  --var system_domain="${SYSTEM_DNS_ZONE_NAME}" \
  ${opsfile_args} \
  "${PAAS_CF_DIR}/manifests/runtime-config/paas-cf-runtime-config.yml"
