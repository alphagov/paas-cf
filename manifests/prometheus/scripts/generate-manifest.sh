#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus/upstream
WORKDIR=${WORKDIR:-.}

opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

alerts_opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/alerts.d/*.yml; do
  alerts_opsfile_args+="-o $i "
done

vars_files=""
# shellcheck disable=SC2153
for i in ${VARS_FILES}; do
  vars_files+="--vars-file $i "
done

# shellcheck disable=SC2086
bosh interpolate \
  --var-errs \
  --vars-store "${VARS_STORE}" \
  ${vars_files} \
  ${opsfile_args} \
  ${alerts_opsfile_args} \
  "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
