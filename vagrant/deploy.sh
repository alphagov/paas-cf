#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

# Load environment variables
# shellcheck disable=SC2091
$("$SCRIPT_DIR/environment.sh" "$@") || exit $?

# Install aws dummy box if not present
if ! vagrant box list | grep -qe "^${VAGRANT_BOX_NAME} "; then
  vagrant box add "${VAGRANT_BOX_NAME}" \
	https://github.com/mitchellh/vagrant-aws/raw/74021d7c9fbc519307d661656f6ce96eeb61153c/dummy.box
fi

vagrant up

VAGRANT_IP=$(vagrant ssh -- curl -qs http://169.254.169.254/latest/meta-data/public-ipv4)
export VAGRANT_IP
export CONCOURSE_URL=http://localhost:8080
export FLY_TARGET=${DEPLOY_ENV}-bootstrap

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

if [ ! -x "$FLY_CMD" ]; then
  FLY_CMD_URL="$CONCOURSE_URL/api/v1/cli?arch=amd64&platform=$(uname | tr '[:upper:]' '[:lower:]')"
  echo "Downloading fly command..."
  curl "$FLY_CMD_URL" -o "$FLY_CMD" && chmod +x "$FLY_CMD"
fi

echo -e "${CONCOURSE_ATC_USER}\n${CONCOURSE_ATC_PASSWORD}" | \
  $FLY_CMD login -t "${FLY_TARGET}" --concourse-url "${CONCOURSE_URL}"

"${SCRIPT_DIR}"/../concourse/scripts/concourse-lite-self-terminate.sh "${DEPLOY_ENV}"
"${SCRIPT_DIR}"/../concourse/scripts/create-deployer.sh "${DEPLOY_ENV}"
"${SCRIPT_DIR}"/../concourse/scripts/destroy-deployer.sh "${DEPLOY_ENV}"

echo
echo "Concourse auth is ${CONCOURSE_ATC_USER} : ${CONCOURSE_ATC_PASSWORD}"
echo "Concourse URL is ${CONCOURSE_URL}"
