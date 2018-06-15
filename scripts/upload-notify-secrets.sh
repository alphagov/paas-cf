#!/bin/bash

set -eu -o pipefail

export PASSWORD_STORE_DIR=${NOTIFY_PASSWORD_STORE_DIR}

NOTIFY_API_KEY="$(pass "notify/${MAKEFILE_ENV_TARGET}/api_key")"

aws s3 cp - "s3://gds-paas-${DEPLOY_ENV}-state/notify-secrets.yml" << EOF
---
secrets:
  notify_api_key: ${NOTIFY_API_KEY}
EOF
