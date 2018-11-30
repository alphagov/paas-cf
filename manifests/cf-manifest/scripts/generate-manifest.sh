#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
CF_DEPLOYMENT_DIR=${PAAS_CF_DIR}/manifests/cf-deployment
PROMETHEUS_DEPLOYMENT_DIR=${PAAS_CF_DIR}/manifests/prometheus/upstream
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
  if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
    opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/scale-down-dev-datadog.yml"
  fi
fi

if [ "${DISABLE_USER_CREATION}" = "false" ] ; then
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/uaa-add-google-oauth.yml"
fi

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args="$opsfile_args -o ${PAAS_CF_DIR}/manifests/cf-manifest/operations/scale-down-dev.yml"
fi

vars_store_args=""
if [ -n "${VARS_STORE:-}" ]; then
  vars_store_args=" --var-errs --vars-store ${VARS_STORE}"
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
  --vars-file="${CF_ENV_SPECIFIC_MANIFEST}" \
  --vars-file="${WORKDIR}/environment-variables.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/rename-network-and-deployment.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/aws.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-external-blobstore.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-s3-blobstore.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/use-external-dbs.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/stop-skipping-tls-validation.yml" \
  --ops-file="${CF_DEPLOYMENT_DIR}/operations/enable-service-discovery.yml" \
  --ops-file="${PROMETHEUS_DEPLOYMENT_DIR}/manifests/operators/cf/add-prometheus-uaa-clients.yml" \
  ${opsfile_args} \
  --ops-file="${WORKDIR}/vpc-peering-opsfile/vpc-peers.yml" \
  ${vars_store_args} \
  "${CF_DEPLOYMENT_DIR}/cf-deployment.yml"
