#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
cd "$SCRIPT_DIR"

# Load environment variables
export TARGET_CONCOURSE=bootstrap
# shellcheck disable=SC2091
$("${PROJECT_DIR}/concourse/scripts/environment.sh" "$@")

export VAGRANT_DEFAULT_PROVIDER="aws"
export VAGRANT_BOX_NAME="aws_vagrant_box"

# Install aws dummy box if not present
if ! vagrant box list | grep -qe "^${VAGRANT_BOX_NAME} "; then
  vagrant box add "${VAGRANT_BOX_NAME}" \
    https://github.com/mitchellh/vagrant-aws/raw/74021d7c9fbc519307d661656f6ce96eeb61153c/dummy.box
fi

vagrant up

VAGRANT_IP=$(vagrant ssh -- curl -qs http://169.254.169.254/latest/meta-data/public-ipv4)
export VAGRANT_IP

# Try to start a SSH tunnel
echo "Setting up SSH tunnel to concourse..."
if ! ( [ -a .vagrant/tunnel-ctrl-socket ] && \
  vagrant ssh -- -S .vagrant/tunnel-ctrl-socket -O check ); then
  vagrant ssh -- -L 8080:127.0.0.1:8080 -fN \
    -M -S .vagrant/tunnel-ctrl-socket -o "ExitOnForwardFailure yes"
fi
if ! curl -f -qs http://localhost:8080/login -o /dev/null; then
  echo "Failed creating SSH tunnel to remote concourse: 'vagrant ssh -- -L 8080:127.0.0.1:8080 -N'"
fi

"${PROJECT_DIR}/concourse/scripts/pipelines-deployer.sh"
"${PROJECT_DIR}/concourse/scripts/concourse-lite-self-terminate.sh"

echo
echo "Concourse auth is ${CONCOURSE_ATC_USER} : ${CONCOURSE_ATC_PASSWORD}"
echo "Concourse URL is ${CONCOURSE_URL}"
