#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
CF_MANIFEST_DIR=${PAAS_CF_DIR}/manifests/cf-manifest
CF_DEPLOYMENT_DIR=${PAAS_CF_DIR}/manifests/cf-deployment
SHARED_MANIFEST_DIR=${PAAS_CF_DIR}/manifests/shared
WORKDIR=${WORKDIR:-.}
DISABLED_AZS=${DISABLED_AZS:-}

opsfile_args=""

for i in "${CF_MANIFEST_DIR}"/operations.d/*.yml; do
  opsfile_args="$opsfile_args -o $i"
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/scale-down-dev.yml"
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/change-vm-types-dev.yml"
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/speed-up-deployment-dev.yml"
fi

if [ "${MAKEFILE_ENV_TARGET-}" = "dev" ]; then
  echo "Adding static OAuth credentials for PaaS admin local development." 1>&2
  echo "The callback URL for this client is localhost." 1>&2
  echo "This should only be available in development environments." 1>&2
  echo "If you're seeing this outside a development environment, stop the deployment and find out why." 1>&2
  opsfile_args="$opsfile_args -o ${CF_MANIFEST_DIR}/operations/local-dev-paas-admin-oauth-client.yml"
fi

# We are going to generate a manifest, as if we did not have any isolation
# segments.
#
# We are then going to use the generated manifest as an input to the
# isolation segment generation script, so that our isolation segment diego
# cells instance groups are identical to regular diego cells, except for the
# necessary changes.
#
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
    --ops-file="${WORKDIR}/psn-peering-opsfile/psn-peers.yml" \
    --ops-file="${WORKDIR}/tenant-uaa-clients-opsfile/tenant-uaa-opsfile.yml" \
    "${CF_DEPLOYMENT_DIR}/cf-deployment.yml"
)"

# Now we have a generated manifest, we can add our isolation segments
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

if [ -n "${DISABLED_AZS}" ]; then
  for AZ in ${DISABLED_AZS}; do
  manifest_with_isolation_segments="$(
    bosh interpolate \
    --ops-file <(
      ruby "${CF_MANIFEST_DIR}/scripts/generate-disable-azs-ops-file.rb" "$AZ" \
      <<< "${manifest_with_isolation_segments}"
    ) - <<< "${manifest_with_isolation_segments}"
  )"
  done
fi

# Now we have a manifest with isolation segments, ready for BOSH
echo "$manifest_with_isolation_segments"
