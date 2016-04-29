#!/bin/sh

set -eu

bosh_host=$1
bosh_secrets_file=$2

bosh_password=$(awk '/bosh_admin_password/ { print $2 }' "${bosh_secrets_file}")
bosh -t "${bosh_host}" login admin "${bosh_password}"
bosh target "${bosh_host}"
