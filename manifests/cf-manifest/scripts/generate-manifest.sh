#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
CF_DEPLOYMENT_DIR=${PAAS_CF_DIR}/manifests/cf-deployment
WORKDIR=${WORKDIR:-.}

opsfile_args=""

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args="$opsfile_args -o ${CF_DEPLOYMENT_DIR}/operations/scale-to-one-az.yml"
fi

for i in "${PAAS_CF_DIR}"/manifests/cf-manifest/operations.d/*.yml; do
  opsfile_args="$opsfile_args -o $i"
done

if [ "${ENABLE_DATADOG}" = "true" ] ; then
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/datadog.yml"
fi

if [ "${DISABLE_USER_CREATION}" = "false" ] ; then
   opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/uaa-add-google-oauth.yml"
fi

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/scale-down-dev.yml"
fi

# shellcheck disable=SC2086
bosh interpolate \
  --var-file ipsec_ca.private_key="${WORKDIR}/ipsec-CA/ipsec-CA.key" \
  --var-file ipsec_ca.certificate="${WORKDIR}/ipsec-CA/ipsec-CA.crt" \
  --vars-file="${PAAS_CF_DIR}/manifests/cf-manifest/data/000-aws-rds-combined-ca-bundle-pem.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/vpc.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/bosh.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/concourse.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${WORKDIR}/cf-secrets/cf-secrets.yml" \
  --vars-file="${WORKDIR}/logit-secrets/logit-secrets.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/variables.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/cf-manifest/static-ips-and-ports.yml" \
  --vars-file="${CF_ENV_SPECIFIC_MANIFEST}" \
  --vars-file="${WORKDIR}/environment-variables/environment-variables.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/rename-deployment.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/rename-network.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/aws.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-external-blobstore.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-s3-blobstore.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-external-dbs.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/stop-skipping-tls-validation.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/enable-uniq-consul-node-name.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-bosh-dns-rename-network-and-deployment.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-bosh-dns-for-containers.yml" \
  ${opsfile_args} \
  --ops-file="${WORKDIR}/vpc-peering-opsfile/vpc-peers.yml" \
  "$@" \
  "${CF_DEPLOYMENT_DIR}/cf-deployment.yml"
