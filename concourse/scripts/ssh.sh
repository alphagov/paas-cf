#!/bin/bash

set -euo pipefail
key=/tmp/concourse_id_rsa.$RANDOM
trap 'rm -f $key' EXIT

eval "$(make dev showenv | grep CONCOURSE_IP=)"

aws s3 cp "s3://${DEPLOY_ENV}-state/concourse_id_rsa" $key && chmod 400 $key

echo
aws s3 cp "s3://${DEPLOY_ENV}-state/generated-concourse-secrets.yml" - | \
ruby -ryaml -e 'puts "\Sudo password is " + YAML.load(STDIN)["secrets"]["concourse_vcap_password_orig"]' 
echo

ssh -i $key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null vcap@"$CONCOURSE_IP"
