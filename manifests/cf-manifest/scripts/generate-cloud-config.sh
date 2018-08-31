#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
WORKDIR=${WORKDIR:-.}

bosh interpolate \
  --var-errs \
  --vars-file="${WORKDIR}/terraform-outputs/vpc.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/bosh.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/concourse.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${WORKDIR}/cf-secrets/cf-secrets.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/variables.yml" \
  --vars-file="${CF_ENV_SPECIFIC_MANIFEST}" \
  --vars-file="${WORKDIR}/environment-variables/environment-variables.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/cloud-config/operations/050-rds-broker.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/cloud-config/operations/060-cdn-broker.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/cloud-config/operations/070-elasticache-broker.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/cloud-config/operations/090-prometheus.yml" \
  "$@" \
  "${PAAS_CF_DIR}/manifests/cf-manifest/cloud-config/000-base-cloud-config.yml"
