#!/bin/bash

set -eu

trap 'make dev stop-tunnel; rm -f /tmp/manifest.yml' EXIT

echo "Making SSH tunnel to Bosh..."
make dev tunnel TUNNEL=25555:10.0.0.6:25555

echo
echo "Logging into and targeting Bosh..."
BOSH_PASSWORD=$(aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/bosh-secrets.yml" - | awk '/bosh_admin_password/ {print $2}')
bosh login admin "$BOSH_PASSWORD"
bosh target localhost

echo
echo "Downloading CloudFoundry manifest..."
aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/cf-manifest.yml" /tmp/manifest.yml
bosh deployment /tmp/manifest.yml

echo
echo "You are now in a local shell"
echo "The bosh CLI is logged into the remote BOSH"
echo "Run bosh commands such as: bosh vms"
bash
