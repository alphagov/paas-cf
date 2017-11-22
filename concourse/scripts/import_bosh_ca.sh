#!/bin/sh
set -eu

echo "Adding bosh-CA to root certificates"
tar -xzf bosh-CA/bosh-CA.tar.gz -C /usr/local/share/ca-certificates bosh-CA.crt

UPDATE_OUTPUT=$(update-ca-certificates 2>&1)
set +e
printf "%s" "${UPDATE_OUTPUT}" | grep -v "^WARNING: ca-certificates\.crt does not contain exactly one certificate or CRL: skipping$"
set -e
