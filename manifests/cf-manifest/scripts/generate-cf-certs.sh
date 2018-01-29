#!/bin/sh

set -e
set -u

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
apps_domain,${APPS_DOMAINS}
system_domain,${SYSTEM_DOMAINS}
saml,
auctioneer_server,auctioneer.service.cf.internal
auctioneer_client,
bbs_server,bbs.service.cf.internal
bbs_client,
router_internal,${APPS_DOMAINS}
uaa_jwt_signing,
uaa_internal,uaa.service.cf.internal
consul_server,server.dc1.cf.internal,server.dc2.cf.internal
consul_agent,
doppler,
metron,
trafficcontroller,
cc_trafficcontroller,
rep_server,*.cell.service.cf.internal,cell.service.cf.internal
rep_client,
reverse_log_proxy,
statsd_injector,
scalablesyslog_adapter,
scalablesyslog_adapter_scheduler_api,
scalablesyslog_adapter_scheduler_client,
cc_server,cloud-controller-ng.service.cf.internal
cc_client,
cc_uploader_server,cc-uploader.service.cf.internal
"

# Certificates that will not be rotated
ROTATION_BLACK_LIST="
apps_domain
system_domain
"

generate_cert() {
  _cn="${1}"
  _domains="${2}"
  _target_dir="${3}"

  certstrap request-cert \
    --passphrase "" \
    --common-name "${_cn}" \
		${domains:+--domain "${_domains}"}
  certstrap sign \
    --CA "${CA_NAME}" \
    --passphrase "" \
    --years "2" \
    "${_cn}"

  mv "out/${_cn}.key" "${_target_dir}/"
  mv "out/${_cn}.csr" "${_target_dir}/"
  mv "out/${_cn}.crt" "${_target_dir}/"
}

rotate_cert() {
  _cn="${1}"
  _domains="${2}"
  _target_dir="${3}"

  mv "${_target_dir}/${_cn}.key" "${_target_dir}/${_cn}_old.key"
  mv "${_target_dir}/${_cn}.csr" "${_target_dir}/${_cn}_old.csr"
  mv "${_target_dir}/${_cn}.crt" "${_target_dir}/${_cn}_old.crt"

  generate_cert "${_cn}" "${_domains}" "${_target_dir}"
}

is_cert_blacklisted() {
  _cn="$1"
  for blacklisted_cert in ${ROTATION_BLACK_LIST}; do
    if [ "${_cn}" = "${blacklisted_cert}" ];then
      return 0
    fi
  done
  return 1
}

CERTS_DIR=$(cd "$1" && pwd)
CA_TARBALL="$2"
ACTION="${3:-}"
if [ "${ACTION}" != "create" ] && [ "${ACTION}" != "rotate" ]; then
  cat <<EOF
Usage:
  $0 <create|rotate>
EOF
  exit 1
fi

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
    echo "Certificate ${cn} is already generated."
    if [ "${ACTION}" = "rotate" ]; then
      if is_cert_blacklisted "${cn}"; then
        echo "Certificate ${cn} is blacklisted for rotation. Skipping."
      else
        echo "Rotating certificate..."
        rotate_cert "${cn}" "${domains}" "${CERTS_DIR}"
      fi
    else
      echo "Skipping creation."
    fi
  else
    echo "Creating certificate ${cn}..."
    generate_cert "${cn}" "${domains}" "${CERTS_DIR}"
  fi
done

