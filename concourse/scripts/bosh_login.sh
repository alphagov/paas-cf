#!/bin/sh

set -eu

bosh_secrets_file=$1
bosh_ip=${BOSH_IP-"10.0.0.6"}

bosh_password=$(awk '/bosh_admin_password/ { print $2 }' "${bosh_secrets_file}")
bosh -t "${bosh_ip}" login admin "${bosh_password}"
bosh target "${bosh_ip}"
