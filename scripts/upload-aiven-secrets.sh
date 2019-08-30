#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${AIVEN_PASSWORD_STORE_DIR}

CREDHUB_NAMESPACE=${CREDHUB_NAMESPACE:-/concourse/main/create-cloudfoundry}

if [ -n "${AIVEN_PASSWORD_STORE_HIGH_DIR:-}" ]; then
  export PASSWORD_STORE_DIR=${AIVEN_PASSWORD_STORE_HIGH_DIR}
fi
AIVEN_API_TOKEN=$(pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token")

S3_SECRETS=$(mktemp secrets.yml.XXXXXX)
CREDHUB_SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm "${S3_SECRETS}"; rm "${CREDHUB_SECRETS}"' EXIT

cat > "${S3_SECRETS}" << EOF
---
aiven_api_token: ${AIVEN_API_TOKEN}
EOF

cat > "${CREDHUB_SECRETS}" << EOF
---
credentials:
  - name: ${CREDHUB_NAMESPACE}/aiven_api_token
    type: value
    value: ${AIVEN_API_TOKEN}
EOF

aws s3 cp "${S3_SECRETS}" "s3://gds-paas-${DEPLOY_ENV}-state/aiven-secrets.yml"

./scripts/credhub-import.sh "$(pwd)/${CREDHUB_SECRETS}"
