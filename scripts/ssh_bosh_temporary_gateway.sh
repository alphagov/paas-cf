#!/bin/bash

if [ -z "${VM_IP:-}" ]; then
  echo "Error: IPv4 address of the gateway VM must be provided as VM_IP env variable."
  exit 1
fi

BOSH_KEY=/tmp/bosh_id_rsa.$RANDOM
DEPLOY_KEY=/tmp/deploy_id_rsa.$RANDOM
trap 'rm -f ${BOSH_KEY} ${DEPLOY_KEY}' EXIT
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh_id_rsa" ${BOSH_KEY} && chmod 400 ${BOSH_KEY}
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/id_rsa" ${DEPLOY_KEY} && chmod 400 ${DEPLOY_KEY}

BOSH_IP=10.0.0.6
echo
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-secrets.yml" - | \
  ruby -ryaml -e 'puts "Sudo password is " + YAML.load(STDIN)["secrets"]["bosh_vcap_password_orig"]'
echo

SSH_OPTIONS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60'
PROXY_COMMAND="ssh ${SSH_OPTIONS} -i ${DEPLOY_KEY} ec2-user@${VM_IP} -W ${BOSH_IP}:22"
# shellcheck disable=SC2086
ssh ${SSH_OPTIONS} -o ProxyCommand="${PROXY_COMMAND}" -i "${BOSH_KEY}" vcap@"${BOSH_IP}"
