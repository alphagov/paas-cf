#!/bin/bash

set -euo pipefail
TUNNEL=${1:-}
SOCKET_DIR=~/.ssh
SOCKET_DEF=%r@%h:%p
SOCKET=$SOCKET_DIR/$SOCKET_DEF

download_key() {
  key=/tmp/concourse_id_rsa.$RANDOM
  trap 'rm -f $key' EXIT

  eval "$(make dev showenv | grep CONCOURSE_IP=)"

  aws s3 cp "s3://${DEPLOY_ENV}-state/concourse_id_rsa" $key && chmod 400 $key
}

ssh_concourse() {
  echo
  aws s3 cp "s3://${DEPLOY_ENV}-state/generated-concourse-secrets.yml" - | \
    ruby -ryaml -e 'puts "Sudo password is " + YAML.load(STDIN)["secrets"]["concourse_vcap_password_orig"]'
  echo

  ssh -i $key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60 \
    vcap@"$CONCOURSE_IP"
}

create_tunnel() {
  echo "Creating tunnel at socket $(print_socket) to ${TUNNEL}"
  ssh -i $key -fNTM -o ControlPath=${SOCKET} -o "ExitOnForwardFailure yes" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60 \
    -L "${TUNNEL}" vcap@"${CONCOURSE_IP}"
}

stop_tunnel() {
  echo "Stopping tunnel at socket $(print_socket)"
  ssh -T -O "exit" -o ControlPath=${SOCKET} vcap@"${CONCOURSE_IP}"
}

print_socket() {
  echo -n $SOCKET_DIR/vcap@"${CONCOURSE_IP}"
}

download_key

if [[ -z "${TUNNEL}" ]]; then
  ssh_concourse
elif [[ "${TUNNEL}" != "stop" ]]; then
  create_tunnel
else
  stop_tunnel
fi
