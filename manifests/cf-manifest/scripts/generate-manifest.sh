#!/bin/bash

set -eu -o pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf/}
WORKDIR=${WORKDIR:-}

datadog_opsfile=${PAAS_CF_DIR}manifests/cf-manifest/operations/noop.yml
if [ "${ENABLE_DATADOG}" = "true" ] ; then
  datadog_opsfile="${PAAS_CF_DIR}manifests/cf-manifest/operations/090-datadog-nozzle.yml"
fi

oauth_opsfile=${PAAS_CF_DIR}manifests/cf-manifest/operations/noop.yml
if [ "${DISABLE_USER_CREATION}" = "false" ] ; then
   oauth_opsfile="${PAAS_CF_DIR}manifests/cf-manifest/operations/100-oauth.yml"
fi

bosh interpolate \
  --var-errs \
  --vars-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/data/000-aws-rds-combined-ca-bundle-pem.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/vpc.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/bosh.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/concourse.yml" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${WORKDIR}/cf-secrets/cf-secrets.yml" \
  --vars-file="${WORKDIR}/certs-yaml/certs.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/variables.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/cf-manifest/static-ips-and-ports.yml" \
  --vars-file="${CF_ENV_SPECIFIC_MANIFEST}" \
  --vars-file="${WORKDIR}/environment-variables/environment-variables.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/operations/040-graphite.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/operations/050-rds-broker.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/operations/060-cdn-broker.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/operations/070-elasticache-broker.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/operations/080-logsearch.yml" \
  --ops-file="${WORKDIR}/grafana-dashboards-opsfile/grafana-dashboards-opsfile.yml" \
  --ops-file="${WORKDIR}/vpc-peering-opsfile/vpc-peers.yml" \
  --ops-file="${datadog_opsfile}" \
  --ops-file="${oauth_opsfile}" \
  --ops-file="${PAAS_CF_DIR}/manifests/cf-manifest/manifest/operations/999-prune.yml" \
  "$@" \
  "${PAAS_CF_DIR}/manifests/cf-manifest/manifest/000-base-cf-deployment.yml"
