#!/bin/bash
set -eu

help() {
  cat <<-EOF
  Usage $0 [credhub credentials file]

  This scripts acts as a proxy to `credhub import` in the target environment.
  See the credhub cli documentation for how the file should be formatted.
EOF
}

if [ $# -lt 1 ]; then
    help
    exit 1
fi

BOSH_ID_RSA="$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/id_rsa" - | base64)"
export BOSH_ID_RSA

BOSH_CA_CERT="$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-CA.crt" -)"
export BOSH_CA_CERT

BOSH_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:deploy_env,Values=${DEPLOY_ENV}" 'Name=tag:instance_group,Values=bosh' \
    --query 'Reservations[].Instances[].PublicIpAddress' --output text)
export BOSH_IP

BOSH_CLIENT_SECRET=$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-vars-store.yml" - | \
    ruby -ryaml -e 'print YAML.load(STDIN)["admin_password"]')
export BOSH_CLIENT_SECRET

CREDHUB_CLIENT='credhub-admin'
CREDHUB_SECRET=$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-secrets.yml" - | \
    ruby -ryaml -e 'print YAML.load(STDIN).dig("secrets", "bosh_credhub_admin_client_password")')
CREDHUB_CA_CERT="$(cat <<EOCERTS
$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-vars-store.yml" - | \
  ruby -ryaml -e 'print YAML.load(STDIN).dig("credhub_tls", "ca")')
$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-vars-store.yml" - | \
  ruby -ryaml -e 'print YAML.load(STDIN).dig("uaa_ssl", "ca")')
EOCERTS
)"
export CREDHUB_CLIENT CREDHUB_SECRET CREDHUB_CA_CERT

[ ! -d "${HOME}/.bosh_history" ] && mkdir ~/.bosh_history

touch "${HOME}/.bosh_history/${DEPLOY_ENV}"

docker run \
    --rm \
    --env "BOSH_ID_RSA" \
    --env "BOSH_IP" \
    --env "BOSH_CLIENT=admin" \
    --env "BOSH_CLIENT_SECRET" \
    --env "BOSH_ENVIRONMENT=bosh.${SYSTEM_DNS_ZONE_NAME}" \
    --env "BOSH_CA_CERT" \
    --env "BOSH_DEPLOYMENT=${DEPLOY_ENV}" \
    --env "CREDHUB_SERVER=https://bosh.${SYSTEM_DNS_ZONE_NAME}:8844/api" \
    --env "CREDHUB_CLIENT" --env "CREDHUB_SECRET" --env "CREDHUB_CA_CERT" \
    --env "CREDHUB_PROXY=socks5://localhost:25555" \
    -v "${HOME}/.bosh_history/${DEPLOY_ENV}:/root/.bash_history" \
    --mount type=bind,source="$1",target=/root/import.yml \
    governmentpaas/bosh-shell:47b25fd03f4dcaf8851ee859f5e8ec0b915cf8fc \
    -c "credhub import -f /root/import.yml"
