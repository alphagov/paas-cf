#!/bin/bash

hashed_password() {
  echo "$1" | shasum -a 256 | base64 | head -c 32
}

PROJECT_DIR=$(cd "$(dirname "$0")"/.. && pwd)

export DEPLOY_ENV=${DEPLOY_ENV:-$1}
if [[ -z "${DEPLOY_ENV}" ]]; then
  echo "Must provide environment name: $0 <deploy_env>" 1>&2
  exit 100
fi

CONCOURSE_ATC_USER=${CONCOURSE_ATC_USER:-admin}
if [[ -z "$CONCOURSE_ATC_PASSWORD" ]]; then
  CONCOURSE_ATC_PASSWORD=$(hashed_password "${AWS_SECRET_ACCESS_KEY}:${DEPLOY_ENV}:atc")
else
  echo "\$CONCOURSE_ATC_PASSWORD already set, not generating. Unset with 'unset CONCOURSE_ATC_PASSWORD'" 1>&2
fi

cat <<EOF
export DEPLOY_ENV=$DEPLOY_ENV
export VAGRANT_DEFAULT_PROVIDER=aws
export VAGRANT_BOX_NAME=aws_vagrant_box
export CONCOURSE_ATC_USER=${CONCOURSE_ATC_USER}
export CONCOURSE_ATC_PASSWORD=${CONCOURSE_ATC_PASSWORD}
export FLY_TARGET=${DEPLOY_ENV}-bootstrap
export FLY_CMD=${FLY_CMD:-$PROJECT_DIR/fly}
EOF

echo "Deploy environment name: $DEPLOY_ENV" 1>&2
echo "Concourse auth is ${CONCOURSE_ATC_USER} : ${CONCOURSE_ATC_PASSWORD}" 1>&2

