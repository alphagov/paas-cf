#!/bin/bash -e
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
cd $SCRIPT_DIR

hashed_password() {
  echo $1 | shasum -a 256 | base64 | head -c 32
}

export DEPLOY_ENV=${DEPLOY_ENV:-$1}
[[ -z "${DEPLOY_ENV}" ]] && echo "Must provide environment name" && exit 100

export VAGRANT_PRIVATE_KEY_PATH=${VAGRANT_PRIVATE_KEY_PATH:-~/.ssh/insecure-deployer}
export VAGRANT_DEFAULT_PROVIDER="aws"
export VAGRANT_BOX_NAME="aws_vagrant_box"
export CONCOURSE_ATC_USER=${CONCOURSE_ATC_USER:-admin} # This can be improved to grab admin name locally from manifest. Currently 'admin' is hardcoded elsewhere.
export CONCOURSE_ATC_PASSWORD=${CONCOURSE_ATC_PASSWORD:-$(hashed_password ${AWS_SECRET_ACCESS_KEY}:${DEPLOY_ENV}:atc)}
export CONCOURSE_DB_PASSWORD=${CONCOURSE_DB_PASSWORD:-$(hashed_password ${AWS_SECRET_ACCESS_KEY}:${DEPLOY_ENV}:db)}
export FLY_TARGET=${DEPLOY_ENV}-bootstrap

# Install aws dummy box if not present
if ! vagrant box list | grep -qe "^${VAGRANT_BOX_NAME} "; then
  vagrant box add ${VAGRANT_BOX_NAME} \
	https://github.com/mitchellh/vagrant-aws/raw/74021d7c9fbc519307d661656f6ce96eeb61153c/dummy.box
fi

vagrant up

export VAGRANT_IP=$(vagrant ssh-config | sed -n 's/.*HostName //p')
export CONCOURSE_URL=http://${VAGRANT_IP}:8080

echo -e "${CONCOURSE_ATC_USER}\n${CONCOURSE_ATC_PASSWORD}" | \
  fly login -t ${FLY_TARGET} --concourse-url ${CONCOURSE_URL}

${SCRIPT_DIR}/../concourse/scripts/create-deployer.sh ${DEPLOY_ENV}
${SCRIPT_DIR}/../concourse/scripts/destroy-deployer.sh ${DEPLOY_ENV}

echo
echo "Concourse auth is ${CONCOURSE_ATC_USER} : ${CONCOURSE_ATC_PASSWORD}"
echo "Concourse URL is ${CONCOURSE_URL}"
