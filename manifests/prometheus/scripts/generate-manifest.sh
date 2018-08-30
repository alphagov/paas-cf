#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus/upstream

opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

# shellcheck disable=SC2086
bosh interpolate \
  --var-errs \
  --vars-store "${VARS_STORE}" \
  ${opsfile_args} \
  "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
