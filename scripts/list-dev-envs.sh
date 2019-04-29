#!/bin/sh

if [ -z "${AWS_ACCESS_KEY_ID:-}" ]; then
  >&2 echo "Must be run with AWS dev account creds"
  exit 1
fi

aws s3 ls | grep 'gds-paas.*-state' | grep -v 'account-wide' | cut -d '-' -f 5

