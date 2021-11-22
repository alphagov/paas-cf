#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
SHARED_MANIFEST_DIR=${PAAS_CF_DIR}/manifests/shared
APP_AUTOSCALER_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/app-autoscaler/upstream
WORKDIR=${WORKDIR:-.}


opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/app-autoscaler/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
  opsfile_args+="-o ${PAAS_CF_DIR}/manifests/app-autoscaler/operations/scale-down-dev.yml "
fi

variables_file="$(mktemp)"
trap 'rm -f "${variables_file}"' EXIT

echo "
---
deploy_env: $DEPLOY_ENV
system_domain: $SYSTEM_DNS_ZONE_NAME
app_domain: $APPS_DNS_ZONE_NAME
aws_account: $AWS_ACCOUNT
bosh_ca_cert: $BOSH_CA_CERT
vcap_password: $VCAP_PASSWORD

cf_client_id: app_autoscaler
database:
  name: app_autoscaler
  port: 5432
  host: ((terraform_outputs_cf_db_address))
  username: app_autoscaler
  password: ((external_app_autoscaler_database_password))
  sslmode: verify-full
  scheme: postgres
  tls:
    ca: ((aws_rds_combined_ca_bundle))

skip_ssl_validation: false
" \
  | bosh interpolate - \
    --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
    --vars-file="${SHARED_MANIFEST_DIR}/data/aws-rds-combined-ca-bundle-pem.yml" \
  > "${variables_file}"

# shellcheck disable=SC2086
bosh interpolate \
  ${opsfile_args} \
  --vars-file="${variables_file}" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  "${APP_AUTOSCALER_BOSHRELEASE_DIR}/templates/app-autoscaler-deployment.yml" \
| sed "s@dns_api_client_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_api_client_tls.@g" \
| sed "s@dns_api_server_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_api_server_tls.@g" \
| sed "s@/bosh-autoscaler/cf/nats_client_cert[.]@/$DEPLOY_ENV/$DEPLOY_ENV/nats_client_cert.@g" \
| sed "s@dns_healthcheck_client_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_healthcheck_client_tls.@g" \
| sed "s@dns_healthcheck_server_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_healthcheck_server_tls.@g" \
| sed "s@loggregator_tls_rlp[.]@/$DEPLOY_ENV/$DEPLOY_ENV/loggregator_tls_rlp.@g" \
| sed "s@loggregator_ca[.]@/$DEPLOY_ENV/$DEPLOY_ENV/loggregator_ca.@g" \
| sed "s@loggregator_tls_agent[.]@/$DEPLOY_ENV/$DEPLOY_ENV/loggregator_tls_agent.@g" \
| sed "s@cf_client_secret@/$DEPLOY_ENV/$DEPLOY_ENV/uaa_clients_app_autoscaler_secret@g"
