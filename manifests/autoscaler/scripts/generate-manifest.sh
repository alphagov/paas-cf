#!/bin/bash

set -euo pipefail

PAAS_CF_DIR=${PAAS_CF_DIR:-paas-cf}
AUTOSCALER_BOSHRELEASE_DIR=${PAAS_CF_DIR}/manifests/autoscaler/upstream
WORKDIR=${WORKDIR:-.}


opsfile_args=""
for i in "${PAAS_CF_DIR}"/manifests/autoscaler/operations.d/*.yml; do
  opsfile_args+="-o $i "
done

# if [ "${SLIM_DEV_DEPLOYMENT-}" = "true" ]; then
#   opsfile_args+="-o ${PAAS_CF_DIR}/manifests/autoscaler/operations/scale-down-dev.yml "
#   opsfile_args+="-o ${PAAS_CF_DIR}/manifests/autoscaler/operations/speed-up-deployment-dev.yml "
# fi

variables_file="$(mktemp)"
trap 'rm -f "${variables_file}"' EXIT

cat <<EOF > "${variables_file}"
---
deploy_env: $DEPLOY_ENV
system_domain: $SYSTEM_DNS_ZONE_NAME
app_domain: $APPS_DNS_ZONE_NAME
aws_account: $AWS_ACCOUNT
bosh_ca_cert: "$BOSH_CA_CERT"
vcap_password: $VCAP_PASSWORD

cf_client_id: autoscaler
database:
  name: autoscaler
  port: 5432
  host: ((terraform_outputs_cf_db_address))
  username: autoscaler
  password: ((external_autoscaler_db_password))
  sslmode: verify-full
  scheme: postgres
  tls:
    ca: ~
EOF

# shellcheck disable=SC2086
bosh interpolate \
  --vars-file="${variables_file}" \
  --vars-file="${WORKDIR}/terraform-outputs/cf.yml" \
  ${opsfile_args} \
  "${AUTOSCALER_BOSHRELEASE_DIR}/templates/app-autoscaler-deployment.yml" \
| sed "s@dns_api_client_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_api_client_tls.@g" \
| sed "s@dns_api_server_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_api_server_tls.@g" \
| sed "s@dns_healthcheck_client_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_healthcheck_client_tls.@g" \
| sed "s@dns_healthcheck_server_tls[.]@/$DEPLOY_ENV/$DEPLOY_ENV/dns_healthcheck_server_tls.@g" \
| sed "s@cf_client_secret@/$DEPLOY_ENV/$DEPLOY_ENV/uaa_clients_autoscaler_secret@g"
