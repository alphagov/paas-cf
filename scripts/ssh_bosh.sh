#!/bin/bash
set -euo pipefail

BOSH_KEY=/tmp/bosh_id_rsa.$RANDOM
CONCOURSE_KEY=/tmp/concourse_id_rsa.$RANDOM
trap 'rm -f ${BOSH_KEY} ${CONCOURSE_KEY}' EXIT
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh_id_rsa" ${BOSH_KEY} && chmod 400 ${BOSH_KEY}
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/concourse_id_rsa" ${CONCOURSE_KEY} && chmod 400 ${CONCOURSE_KEY}

BOSH_IP=10.0.0.6
CONCOURSE_IP=$(aws ec2 describe-instances \
                --filters 'Name=tag:Name,Values=concourse/*' "Name=key-name,Values=${DEPLOY_ENV}_concourse_key_pair" \
                --query 'Reservations[].Instances[].PublicIpAddress' --output text)

echo
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-secrets.yml" - | \
  ruby -ryaml -e 'puts "Sudo password is " + YAML.load(STDIN)["secrets"]["bosh_vcap_password_orig"]'
echo

SSH_OPTIONS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60'
PROXY_COMMAND="ssh ${SSH_OPTIONS} -i ${CONCOURSE_KEY} vcap@${CONCOURSE_IP} -W ${BOSH_IP}:22"

# shellcheck disable=SC2086
ssh ${SSH_OPTIONS} -o ProxyCommand="${PROXY_COMMAND}" -i ${BOSH_KEY} vcap@${BOSH_IP}
