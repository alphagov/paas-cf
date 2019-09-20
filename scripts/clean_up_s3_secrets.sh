#!/usr/bin/env bash

set -eu

state_bucket=gds-paas-${DEPLOY_ENV}-state

aws s3 rm "s3://${state_bucket}/aiven-secrets.yml"
aws s3 rm "s3://${state_bucket}/github-oauth-secrets.yml"
aws s3 rm "s3://${state_bucket}/google-oauth-secrets.yml"
aws s3 rm "s3://${state_bucket}/logit-secrets.yml"
aws s3 rm "s3://${state_bucket}/microsoft-oauth-secrets.yml"
aws s3 rm "s3://${state_bucket}/notify-secrets.yml"
aws s3 rm "s3://${state_bucket}/pagerduty-secrets.yml"
