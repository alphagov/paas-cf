#!/bin/bash

set -eu
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("${SCRIPT_DIR}/environment.sh")
"${SCRIPT_DIR}/fly_sync_and_login.sh"

OUTPUT_FILE=$(mktemp -t bosh-cli.XXXXXX)
trap 'rm -f "${OUTPUT_FILE}"' EXIT

generate_config(){
  cat <<EOF
---
platform: linux

image: docker:///governmentpaas/bosh-cli

inputs:
  - name: paas-cf
  - name: cf-manifest
  - name: bosh-secrets
run:
  path: sh
  args:
  - -c
  - -e
  - |
    ./paas-cf/concourse/scripts/bosh_login.sh bosh.${SYSTEM_DNS_ZONE_NAME} bosh-secrets/bosh-secrets.yml

    uuid=\$(bosh status --uuid)
    sed -e "s/^director_uuid:.*$/director_uuid: \${uuid}/" cf-manifest/cf-manifest.yml > cf-manifest-with-uuid.yml
    bosh deployment ./cf-manifest-with-uuid.yml
EOF
}

generate_config > /dev/null

$FLY_CMD -t "${FLY_TARGET}" \
  execute \
  --inputs-from=create-bosh-cloudfoundry/cf-deploy \
  --config=<(generate_config) \
  | tee "${OUTPUT_FILE}"

BUILD_NUMBER=$(awk '/executing build/ { print $3 }' "${OUTPUT_FILE}")

$FLY_CMD -t "${FLY_TARGET}" \
  intercept \
  --build="${BUILD_NUMBER}"\
  --step=one-off \
  "${@:-sh}"
