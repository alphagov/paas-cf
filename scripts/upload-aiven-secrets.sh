#!/bin/sh

set -eu

export PASSWORD_STORE_DIR=${AIVEN_PASSWORD_STORE_DIR}

if [ -n "${AIVEN_PASSWORD_STORE_HIGH_DIR:-}" ]; then
  export PASSWORD_STORE_DIR=${AIVEN_PASSWORD_STORE_HIGH_DIR}
fi
AIVEN_API_TOKEN=$(pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token")

SECRETS=$(mktemp secrets.yml.XXXXXX)
trap 'rm  "${SECRETS}"' EXIT

cat > "$SECRETS" << EOF
---
aiven_api_token: $AIVEN_API_TOKEN
EOF

aws s3 cp "$SECRETS" "s3://gds-paas-${DEPLOY_ENV}-state/aiven-secrets.yml"
