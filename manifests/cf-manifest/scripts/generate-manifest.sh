#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
CF_MANIFEST_DIR=${PAAS_CF_DIR}/manifests/cf-manifest
CF_DEPLOYMENT_DIR=${PAAS_CF_DIR}/manifests/cf-deployment
SHARED_MANIFEST_DIR=${PAAS_CF_DIR}/manifests/shared
WORKDIR=${WORKDIR:-.}

opsfile_args=""

for i in "${CF_MANIFEST_DIR}"/operations.d/*.yml; do
  opsfile_args="$opsfile_args -o $i"
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/scale-down-dev.yml"
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/change-vm-types-dev.yml"
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/speed-up-deployment-dev.yml"
fi

# shellcheck disable=SC2086
manifest_without_isolation_segments="$(
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
)"

manifest_with_isolation_segments="${manifest_without_isolation_segments}"

for isolation_segment_definition in "${ENV_SPECIFIC_ISOLATION_SEGMENTS_DIR}"/*.yml; do
  diego_cell_base="$(
    bosh interpolate --path /instance_groups/name=diego-cell - <<< "${manifest_without_isolation_segments}"
  )"

  manifest_with_isolation_segments="$(
    bosh interpolate \
      --ops-file "${CF_MANIFEST_DIR}/operations/add-isolation-segment-bosh-dns-alias.yml" \
      --vars-file "$isolation_segment_definition" \
      --vars-file="${WORKDIR}/environment-variables.yml" \
      --ops-file <(
        ruby "${CF_MANIFEST_DIR}/scripts/generate-isolation-segment-ops-file.rb" \
          --isolation-segment-definition "${isolation_segment_definition}" \
          <<< "${diego_cell_base}"
      ) - <<< "${manifest_with_isolation_segments}"
  )"
done

echo "$manifest_with_isolation_segments"
