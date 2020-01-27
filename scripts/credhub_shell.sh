#!/usr/bin/env bash

set -eu

echo "${0#$PWD}" >> ~/.paas-script-usage

tunnel_mux='/tmp/bosh-ssh-tunnel.mux'

function cleanup () {
  echo 'Closing SSH tunnel'
  ssh -S "$tunnel_mux" -O exit a-destination &>/dev/null || true
}
trap cleanup EXIT

BOSH_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:deploy_env,Values=${DEPLOY_ENV}" 'Name=tag:instance_group,Values=bosh' \
    --query 'Reservations[].Instances[].PublicIpAddress' --output text)
export BOSH_IP

ssh -qfNC -4 -D 25555 \
  -o ExitOnForwardFailure=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ServerAliveInterval=30 \
  -M \
  -S "$tunnel_mux" \
  "$BOSH_IP"

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

export CREDHUB_SERVER="https://bosh.${SYSTEM_DNS_ZONE_NAME}:8844/api"
export CREDHUB_PROXY="socks5://localhost:25555"

cat <<EOF
-------
                      ____          __
  _____________  ____/ / /_  __  __/ /_
 / ___/ ___/ _ \\/ __  / __ \\/ / / / __ \\
/ /__/ /  /  __/ /_/ / / / / /_/ / /_/ /
\\___/_/   \\___/\\____/_/ /_/\\____/_____/

From this shell, you can access credhub using the credhub cli.
Basic usage:

  \$ credhub find -p /path/of/secrets
  \$ credhub get -n /name/of/secretc

Some useful credentials path are listed below.

$(column -t -s "|" <<PATHS
CF PROMETHEUS PASSWORD|/$DEPLOY_ENV/$DEPLOY_ENV/operator_prometheus_password|Username: operator
PLATFORM PROMETHEUS PASSWORD|/$DEPLOY_ENV/prometheus/prometheus_password|Username: admin
GRAFANA PASSWORD|/$DEPLOY_ENV/prometheus/grafana_password|Username: admin
ALERTMANAGER PASSWORD|/$DEPLOY_ENV/prometheus/alertmanager_password|Username: admin
GRAFANA MONITOR PASSWORD|/$DEPLOY_ENV/prometheus/grafana_mon_password|Username: mon
CF ADMIN PASSWORD|/$DEPLOY_ENV/$DEPLOY_ENV/cf_admin_password
UAA ADMIN CLIENT SECRET|/concourse/main/create-cloudfoundry/uaa_admin_client_secret
CONCOURSE ADMIN USER PASSWORD|/concourse/main/concourse_web_password
PATHS
)
-------
EOF

PS1="CREDHUB ($DEPLOY_ENV) $ " bash --login --norc --noprofile

