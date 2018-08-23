#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
WORKDIR=${WORKDIR:-.}

bosh_password="$(awk '/bosh_admin_password:/ {print $2}' < bosh-secrets/bosh-secrets.yml)"

bosh interpolate prometheus-boshrelease/manifests/prometheus.yml \
  --var-errs \
  --vars-store "${WORKDIR}/prometheus-vars-store-updated/prometheus-vars-store.yml" \
  --vars-file="cf-vars-store/cf-vars-store.yml" \
  --ops-file="${WORKDIR}/prometheus-boshrelease/manifests/operators/monitor-bosh.yml" \
  --var=bosh_url="${BOSH_URL}" \
  --var=bosh_username=admin \
  --var=bosh_password="${bosh_password}" \
  --var-file bosh_ca_cert=bosh-CA-crt/bosh-CA.crt \
  --var=metrics_environment="${CF_DEPLOYMENT_NAME}" \
  --ops-file="${WORKDIR}/prometheus-boshrelease/manifests/operators/monitor-cf.yml" \
  --var=metron_deployment_name="${CF_DEPLOYMENT_NAME}" \
  --var=system_domain="${SYSTEM_DNS_ZONE_NAME}"\
  --var=traffic_controller_external_port=443 \
  --ops-file="${WORKDIR}/prometheus-boshrelease/manifests/operators/enable-cf-route-registrar.yml" \
  --var=cf_deployment_name="${CF_DEPLOYMENT_NAME}" \
  --var=skip_ssl_verify=false \
  --ops-file="${PAAS_CF_DIR}/manifests/prometheus-manifest/operators/iaas-specifics.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/prometheus-manifest/operators/cf-alerts.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/prometheus-manifest/operators/prometheus.yml" \
  --ops-file="${PAAS_CF_DIR}/manifests/prometheus-manifest/operators/alertmanager.yml" \
