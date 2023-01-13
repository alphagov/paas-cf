#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
WORKDIR=${WORKDIR:-.}

opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/cloud-config/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

# shellcheck disable=SC2086
bosh interpolate \
  --vars-file="${WORKDIR}/terraform-outputs/vpc.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/bosh.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/variables.yml" \
  ${opsfile_args} \
  "${PAAS_CF_DIR}/manifests/cloud-config/paas-cf-cloud-config.yml"
