#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
PROM_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/prometheus/upstream
WORKDIR=${WORKDIR:-.}


opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/scale-down-dev.yml "
fi

alerts_opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/prometheus/alerts.d/*.yml; do
  alerts_opsfile_args+="-o $i "
done

if [ "${ENABLE_ALERT_NOTIFICATIONS:-}" == "false" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/prometheus/operations/disable-alert-notifications.yml"
fi

variables_file="$(mktemp)"
trap 'rm -f "${variables_file}"' EXIT

bosh interpolate - \
  --var-errs \
  --vars-file "${WORKDIR}/bosh-vars-store/bosh-vars-store.yml" \
> "${variables_file}" \
<<EOF
---
metrics_environment: $DEPLOY_ENV
bosh_url: $BOSH_URL
uaa_bosh_exporter_client_secret: ((bosh_exporter_password))
system_domain: $SYSTEM_DNS_ZONE_NAME
app_domain: $APPS_DNS_ZONE_NAME
metron_deployment_name: $DEPLOY_ENV
skip_ssl_verify: false
traffic_controller_external_port: 443
uaa_clients_cf_exporter_secret: $UAA_CLIENTS_CF_EXPORTER_SECRET
uaa_clients_firehose_exporter_secret: $UAA_CLIENTS_FIREHOSE_EXPORTER_SECRET
aws_account: $AWS_ACCOUNT
grafana_auth_google_client_id: $GRAFANA_AUTH_GOOGLE_CLIENT_ID
grafana_auth_google_client_secret: $GRAFANA_AUTH_GOOGLE_CLIENT_SECRET
EOF

# shellcheck disable=SC2086
bosh interpolate \
  --vars-file="${variables_file}" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  --vars-file="${WORKDIR}/bosh-secrets/bosh-secrets.yml" \
  --vars-file="${PAAS_CF_DIR}/manifests/prometheus/env-specific/${ENV_SPECIFIC_BOSH_VARS_FILE}" \
  --var-file bosh_ca_cert="${WORKDIR}/bosh-CA-crt/bosh-CA.crt" \
  ${opsfile_args} \
  ${alerts_opsfile_args} \
  "${PROM_BOSHRELEASE_DIR}/manifests/prometheus.yml"
