#!/bin/bash -e
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

export VAGRANT_DEFAULT_PROVIDER="aws"
export VAGRANT_BOX_NAME="aws_vagrant_box"

export DEPLOY_ENV=${DEPLOY_ENV:-$1}
[[ -z "${DEPLOY_ENV}" ]] && echo "Must provide environment name" && exit 100

read -sn 1 -p "This is a destructive operation, are you sure you want to do this [Y/N]? "; [[ ${REPLY:0:1} = [Yy] ]];

# TODO: implement 1 & 2
# 1. Trigger destroy in the deployer concourse, wait to complete
# 2. Trigger destroy in the bootstrap concourse (create that box if not present), wait to complete

# 3. Destroy bootstrap concourse
vagrant destroy -f
