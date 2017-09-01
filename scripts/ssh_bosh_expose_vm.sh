#!/bin/bash

BOSH_KEY=/tmp/bosh_id_rsa.$RANDOM
trap 'rm -f ${BOSH_KEY}' EXIT
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh_id_rsa" ${BOSH_KEY} && chmod 400 ${BOSH_KEY}

BOSH_IP=$(aws ec2 describe-instances \
              --filters 'Name=tag:Name,Values=*' "Name=key-name,Values=${DEPLOY_ENV}_bosh_ssh_key_pair" \
              --query 'Reservations[].Instances[].PublicIpAddress' --output text)
echo
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-secrets.yml" - | \
  ruby -ryaml -e 'puts "Sudo password is " + YAML.load(STDIN)["secrets"]["bosh_vcap_password_orig"]'
echo

SSH_OPTIONS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60'
# shellcheck disable=SC2086
ssh ${SSH_OPTIONS} -i "${BOSH_KEY}" vcap@"${BOSH_IP}"
