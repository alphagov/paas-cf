#!/bin/sh
set -eu

bosh_host=$1
bosh_secrets_file=$2

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
bosh_password=$("${SCRIPT_DIR}"/val_from_yaml.rb secrets.bosh_admin_password "${bosh_secrets_file}")

bosh -t "${bosh_host}" login admin -- "${bosh_password}"
bosh target "${bosh_host}"
