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

# List of certs to generate
# Format:
#
# <name_cert>,<domain1>[,domain2,domain3,...]
#
# Note: ALWAYS add a comma after <name_cert>, even if there are no domains
#
CERTS_TO_GENERATE="
bbs_server,bbs.service.cf.internal
bbs_client,
router_internal,${APPS_DOMAINS}
uaa_jwt_signing,
uaa_internal,uaa.service.cf.internal
consul_server,server.dc1.cf.internal,server.dc2.cf.internal
consul_agent,
apps_domain,${APPS_DOMAINS}
system_domain,${SYSTEM_DOMAINS}
doppler,
metron,
trafficcontroller,
saml,
statsd_injector,
cc_server,cloud-controller-ng.service.cf.internal
cc_client,
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

