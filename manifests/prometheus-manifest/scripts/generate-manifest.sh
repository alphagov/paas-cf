#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus-boshrelease

opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus-manifest/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

# shellcheck disable=SC2086
bosh interpolate \
  ${opsfile_args} \
  "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
