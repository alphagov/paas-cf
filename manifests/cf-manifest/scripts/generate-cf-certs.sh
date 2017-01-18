#!/bin/sh

set -e
set -u

CERTS_DIR=$(cd "$1" && pwd)
CA_TARBALL="$2"
CA_NAME="bosh-CA"

# shellcheck disable=SC2154
# Allow referencing unassigned variables (set -u catches problems)
APPS_DOMAINS="*.${APPS_DNS_ZONE_NAME},${APPS_DNS_ZONE_NAME}"
SYSTEM_DOMAINS="*.${SYSTEM_DNS_ZONE_NAME},${SYSTEM_DNS_ZONE_NAME}"

CERTS_TO_GENERATE="
bbs_server,bbs.service.cf.internal
bbs_client,
router_internal,${APPS_DOMAINS}
uaa_jwt_signing,
consul_server,server.dc1.cf.internal,server.dc2.cf.internal
consul_agent,
apps_domain,${APPS_DOMAINS}
system_domain,${SYSTEM_DOMAINS}
doppler,
metron,
trafficcontroller
"

WORKING_DIR="$(mktemp -dt generate-cf-certs.XXXXXX)"
trap 'rm -rf "${WORKING_DIR}"' EXIT

mkdir "${WORKING_DIR}/out"
echo "Extracting ${CA_NAME} cert"
tar -xvzf "${CA_TARBALL}" -C "${WORKING_DIR}/out"

cd "${WORKING_DIR}"
for cert_entry in ${CERTS_TO_GENERATE}; do
  cn=${cert_entry%%,*}
  domains=${cert_entry#*,}

  if [ -f "${CERTS_DIR}/${cn}.crt" ]; then
    echo "Certificate ${cn} is already generated, skipping."
  else
    certstrap request-cert --passphrase "" --common-name "${cn}" ${domains:+--domain "${domains}"}
    certstrap sign --CA "${CA_NAME}" --passphrase "" "${cn}"
    mv "out/${cn}.key" "${CERTS_DIR}/"
    mv "out/${cn}.csr" "${CERTS_DIR}/"
    mv "out/${cn}.crt" "${CERTS_DIR}/"
  fi
done

# FIXME: Remove this section once it's been cleaned up everywhere.
CERTS_TO_CLEANUP="
router_external
logsearch
metrics
"

for cert_name in ${CERTS_TO_CLEANUP}; do
  for ext in csr crt key; do
    if [ -f "${CERTS_DIR}/${cert_name}.${ext}" ]; then
      rm "${CERTS_DIR}/${cert_name}.${ext}"
    fi
  done
done
