#!/usr/bin/env bash

echo "${0#$PWD}" >> ~/.paas-script-usage

set -euo pipefail

cd "$(mktemp -d -t paas-trusted-people-XXXXX)"

git clone --depth 1 --branch "${PAAS_TRUSTED_PEOPLE_BRANCH:-master}" git@github.com:alphagov/paas-trusted-people.git
aws s3 cp ./paas-trusted-people/users.yml "s3://gds-paas-${DEPLOY_ENV}-state/paas-trusted-people/users.yml"

