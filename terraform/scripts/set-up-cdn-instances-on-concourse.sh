#!/bin/bash
set -eu

ACTION=$1

export TARGET_CONCOURSE=deployer
# shellcheck disable=SC2091
$("./concourse/scripts/environment.sh")

./concourse/scripts/fly_sync_and_login.sh

"${FLY_CMD}" -t "${DEPLOY_ENV}" execute \
  --input paas-cf=. \
  --config <(cat <<EOF
---
inputs:
- name: paas-cf
platform: linux
image_resource:
  type: docker-image
  source:
    repository: governmentpaas/terraform
    tag: 9cad30b5d5889a0b72173f39701d1620e24df82c
run:
  path: sh
  args:
    - -e
    - -c
    - -u
    - |

      export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
      export DEPLOY_ENV=${DEPLOY_ENV}
      export AWS_ACCOUNT=${AWS_ACCOUNT}
      export SYSTEM_DNS_ZONE_NAME=${SYSTEM_DNS_ZONE_NAME}
      export APPS_DNS_ZONE_NAME=${APPS_DNS_ZONE_NAME}

      export SKIP_AWS_CREDENTIAL_VALIDATION=true
      if [ "${ACTION}" == "apply" ]; then
        export TERRAFORM_EXTRA_OPTS="-auto-approve=true"
      elif [ "${ACTION}" == "destroy" ]; then
        export TERRAFORM_EXTRA_OPTS="-force"
      fi

      # We need awscli&jq to get the cert id
      apk add -U groff less python py-pip  jq
      pip install awscli

      cd paas-cf
      ./terraform/scripts/set-up-cdn-instances.sh ${ACTION}
EOF
)
