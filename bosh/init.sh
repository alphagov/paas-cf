#!/bin/bash -e
env=${DEPLOY_ENV:-$1}
DEPLOYER_CONCOURSE=${DEPLOYER_CONCOURSE:-$2}
SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)
BOSH_PORT=${BOSH_PORT:-"25555"}

[ -z "${env}" ]                && echo "Must provide DEPLOY_ENV as \$1 or env. var"     && exit 101
[ -z "${DEPLOYER_CONCOURSE}" ] && echo "Must provide DEPLOYER_CONCOURSE ip as env. var" && exit 102

pushd ${SCRIPT_DIR}

  # TODO: check if you really want/need to re-create the session
  #rm session/* && rmdir session
  [ ! -d session ] && mkdir session
  pushd session
    # Get the key
    ../../concourse/scripts/s3get.sh ${env}-state id_rsa > /dev/null
    chmod 600 id_rsa

    # Create ssh tunnel to concourse if not present yet
    if [[ ! $(netstat -an | grep 127.0.0.1.25555) ]]; then
      ssh -i id_rsa -L ${BOSH_PORT}:10.0.0.6:25555 -fN vcap@${DEPLOYER_CONCOURSE} > /dev/null
    fi

    # Get bosh admin PW
    ../../concourse/scripts/s3get.sh ${env}-state bosh-secrets.yml > /dev/null

    boshpw=$(awk '/bosh_admin_password/ {print $2}' bosh-secrets.yml)

    # Login with bosh cli
    bosh -t https://127.0.0.1:${BOSH_PORT}/ login admin ${boshpw}

    bosh target https://127.0.0.1:${BOSH_PORT}/ ${env}-bosh

    # Select main CF deployment
    uuid=$(bosh status --uuid)
    ../../concourse/scripts/s3get.sh ${env}-state cf-manifest.yml > /dev/null
   sed -i -e "s/^director_uuid:.*$/director_uuid: ${uuid}/" cf-manifest.yml
   bosh deployment cf-manifest.yml
  popd
popd

echo "If you need to enable bosh ssh please source $SCRIPT_DIR/bosh_ssh.sh"
echo ". $SCRIPT_DIR/bosh_ssh.sh"
