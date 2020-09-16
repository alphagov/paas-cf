#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
CF_DEPLOYMENT_DIR=${PAAS_CF_DIR}/manifests/cf-deployment
SHARED_MANIFEST_DIR=${PAAS_CF_DIR}/manifests/shared
WORKDIR=${WORKDIR:-.}

opsfile_args=""

for i in "${PAAS_CF_DIR}"/manifests/cf-manifest/operations.d/*.yml; do
  opsfile_args="$opsfile_args -o $i"
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/scale-down-dev.yml"
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/change-vm-types-dev.yml"
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/speed-up-deployment-dev.yml"
fi

# shellcheck disable=SC2086
bosh interpolate \
  --vars-file="${SHARED_MANIFEST_DIR}/data/aws-rds-combined-ca-bundle-pem.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/vpc.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/bosh.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/variables.yml" \
  --vars-file="${ENV_SPECIFIC_BOSH_VARS_FILE}" \
  --vars-file="${WORKDIR}/environment-variables.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-internal-lookup-for-route-services.yml" \
  ${opsfile_args} \
  --ops-file="${WORKDIR}/vpc-peering-opsfile/vpc-peers.yml" \
  --ops-file="${WORKDIR}/tenant-uaa-clients-opsfile/tenant-uaa-opsfile.yml" \
  "${CF_DEPLOYMENT_DIR}/cf-deployment.yml"
