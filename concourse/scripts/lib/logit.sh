#!/bin/sh
set -e
set -u

get_logit_ca_cert() {
  # shellcheck disable=SC2154
  secrets_uri="s3://${state_bucket}/logit-secrets.yml"
  export logit_ca_cert
  if aws s3 ls "$secrets_uri" > /dev/null ; then
    secrets_file=$(mktemp -t logit-secrets.XXXXXX)

    aws s3 cp "$secrets_uri" "$secrets_file"
    logit_ca_cert=$("${SCRIPT_DIR}/val_from_yaml.rb" meta.logit.ca_cert "$secrets_file")

    rm -f "$secrets_file"
  fi
}
