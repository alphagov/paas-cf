#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus/upstream
WORKDIR=${WORKDIR:-.}


opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/scale-down-dev.yml "
fi

alerts_opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/alerts.d/*.yml; do
  alerts_opsfile_args+="-o $i "
done

varsfile_args=""
for i in ${VARS_FILES}; do
  varsfile_args+="--vars-file $i "
done

vars_store_args=""
if [ -n "${VARS_STORE:-}" ]; then
  vars_store_args=" --var-errs --vars-store ${VARS_STORE}"
fi

if [ "${ENABLE_ALERT_EMAILS:-}" == "false" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/disable-email.yml"
fi

# shellcheck disable=SC2086
bosh interpolate \
  ${varsfile_args} \
  ${opsfile_args} \
  ${alerts_opsfile_args} \
  ${vars_store_args} \
  "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
