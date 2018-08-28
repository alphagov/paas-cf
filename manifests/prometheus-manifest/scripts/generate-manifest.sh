#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus-boshrelease

cat "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
