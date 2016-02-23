#!/bin/sh

set -e

simplepass() {
  pwgen -1s 12
}

vcap_password_orig=$(simplepass)
vcap_password=$(echo "${vcap_password_orig}" | mkpasswd -s -m sha-512)

cat <<EOF
---
  secrets:
    vcap_password_orig: ${vcap_password_orig}
    vcap_password: ${vcap_password}
    cf_db_master_password: $(simplepass)
    cf_db_api_password: $(simplepass)
    cf_db_uaa_password: $(simplepass)
    staging_upload_password: $(simplepass)
    bulk_api_password: $(simplepass)
    nats_password: $(simplepass)
    router_password: $(simplepass)
    uaa_batch_password: $(simplepass)
    uaa_admin_password: $(simplepass)
    cc_db_encryption_key: $(simplepass)
    uaa_admin_client_secret: $(simplepass)
    uaa_cc_client_secret: $(simplepass)
    uaa_cc_routing_secret: $(simplepass)
    uaa_clients_app_direct_secret: $(simplepass)
    uaa_clients_developer_console_secret: $(simplepass)
    uaa_clients_login_secret: $(simplepass)
    uaa_clients_notifications_secret: $(simplepass)
    uaa_clients_doppler_secret: $(simplepass)
    uaa_clients_cloud_controller_username_lookup_secret: $(simplepass)
    uaa_clients_gorouter_secret: $(simplepass)
    uaa_clients_firehose_password: $(simplepass)
    loggregator_endpoint_shared_secret: $(simplepass)
    consul_encrypt_keys:
    - $(simplepass)
EOF
