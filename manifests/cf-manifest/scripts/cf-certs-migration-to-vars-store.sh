#!/bin/sh
set -e -u

process_cf_certs() {
  while read -r a b; do
    [ "${a}" ] || continue
  cat <<EOF
${b}:
  certificate: ((file "cf-certs/$a.crt"))
  private_key: ((file "cf-certs/$a.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
EOF
  done
}

echo "---"
process_cf_certs <<EOF
consul_agent consul_agent
consul_server consul_server

auctioneer_client diego_auctioneer_client
auctioneer_server diego_auctioneer_server
bbs_server diego_bbs_server
bbs_client diego_bbs_client
rep_client diego_rep_client

statsd_injector loggregator_tls_statsdinjector
metron loggregator_tls_metron
doppler loggregator_tls_doppler
trafficcontroller loggregator_tls_tc
cc_trafficcontroller loggregator_tls_cc_tc

reverse_log_proxy adapter_rlp_tls
reverse_log_proxy loggregator_tls_rlp

scalablesyslog_adapter_scheduler_api scheduler_api_tls
scalablesyslog_adapter adapter_tls
scalablesyslog_adapter_scheduler_client scheduler_client_tls

router_internal router_ssl

uaa_internal uaa_ssl
saml uaa_login_saml
cc_server cc_tls

cc_uploader_server cc_bridge_cc_uploader_server

rep_server diego_rep_agent_v2
cc_client cc_bridge_tps
cc_client cc_bridge_cc_uploader

EOF

cat <<"EOF"
uaa_jwt_signing_key_id: ((grab $UAA_JWT_SIGNING_KEY_HASH))
uaa_jwt_signing_key:
  private_key: ((file "cf-certs/uaa_jwt_signing.key"))
uaa_jwt_signing_key_old_id: ((grab $UAA_JWT_SIGNING_KEY_HASH))
uaa_jwt_signing_key_old:
  private_key: ((file "cf-certs/uaa_jwt_signing.key"))
EOF

cat <<EOF
service_cf_internal_ca:
  certificate: ((file "bosh-CA/bosh-CA.crt"))
  private_key: ((file "bosh-CA/bosh-CA.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
consul_agent_ca:
  certificate: ((file "bosh-CA/bosh-CA.crt"))
  private_key: ((file "bosh-CA/bosh-CA.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
loggregator_ca:
  certificate: ((file "bosh-CA/bosh-CA.crt"))
  private_key: ((file "bosh-CA/bosh-CA.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
router_ca:
  certificate: ((file "bosh-CA/bosh-CA.crt"))
  private_key: ((file "bosh-CA/bosh-CA.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
uaa_ca:
  certificate: ((file "bosh-CA/bosh-CA.crt"))
  private_key: ((file "bosh-CA/bosh-CA.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
application_ca:
  certificate: ((file "bosh-CA/bosh-CA.crt"))
  private_key: ((file "bosh-CA/bosh-CA.key"))
  ca: ((file "bosh-CA/bosh-CA.crt"))
EOF

cat <<EOF
service_cf_internal_ca_old:
  certificate: ""
  private_key: ""
  ca: ""
consul_agent_ca_old:
  certificate: ""
  private_key: ""
  ca: ""
loggregator_ca_old:
  certificate: ""
  private_key: ""
  ca: ""
router_ca_old:
  certificate: ""
  private_key: ""
  ca: ""
uaa_ca_old:
  certificate: ""
  private_key: ""
  ca: ""
EOF

