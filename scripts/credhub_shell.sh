#!/usr/bin/env bash

set -eu

CONTAINER_REPO="governmentpaas/bosh-shell"
CONTAINER_TAG="cf791cec329bff5577cd8b3c9511bf89f988b5d4"
CONTAINER="${CONTAINER_REPO}:${CONTAINER_TAG}"

# Setup Bosh variables
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

# Setup Credhub variables
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

# Set up persistent history for the credhub shell
[ ! -d "${HOME}/.credhub_history" ] && mkdir ~/.credhub_history
touch "${HOME}/.credhub_history/${DEPLOY_ENV}"

# Run container
docker run \
    -it \
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
    --env "DEPLOY_ENV" \
    -v "${HOME}/.credhub_history/${DEPLOY_ENV}:/root/.bash_history" \
    -v "${PWD}/scripts/templates/credhub_bashrc.sh:/root/.bashrc" \
    "${CONTAINER}"
