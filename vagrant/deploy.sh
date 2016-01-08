#!/bin/bash -e
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
cd $SCRIPT_DIR

# Load environment variables
$($SCRIPT_DIR/environment.sh $@) || exit $?

# Install aws dummy box if not present
if ! vagrant box list | grep -qe "^${VAGRANT_BOX_NAME} "; then
  vagrant box add ${VAGRANT_BOX_NAME} \
	https://github.com/mitchellh/vagrant-aws/raw/74021d7c9fbc519307d661656f6ce96eeb61153c/dummy.box
fi

vagrant up

export VAGRANT_IP=$(vagrant ssh-config | sed -n 's/.*HostName //p')
export CONCOURSE_URL=http://${VAGRANT_IP}:8080

if [ ! -x $FLY_CMD ]; then
  FLY_CMD_URL="$CONCOURSE_URL/api/v1/cli?arch=amd64&platform=$(uname | tr '[:upper:]' '[:lower:]')"
  echo "Downloading fly command..."
  curl $FLY_CMD_URL -o $FLY_CMD && chmod +x $FLY_CMD
fi

echo -e "${CONCOURSE_ATC_USER}\n${CONCOURSE_ATC_PASSWORD}" | \
  $FLY_CMD login -t ${FLY_TARGET} --concourse-url ${CONCOURSE_URL}

${SCRIPT_DIR}/../concourse/scripts/create-deployer.sh ${DEPLOY_ENV}
${SCRIPT_DIR}/../concourse/scripts/destroy-deployer.sh ${DEPLOY_ENV}

echo
echo "Concourse auth is ${CONCOURSE_ATC_USER} : ${CONCOURSE_ATC_PASSWORD}"
echo "Concourse URL is ${CONCOURSE_URL}"
