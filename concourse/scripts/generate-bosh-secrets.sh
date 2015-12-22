#!/bin/sh

pwgen() {
   openssl rand -base64 12
}

cat <<EOF
---
secrets:
  bosh_postgres_password: $(pwgen)
  bosh_nats_password: $(pwgen)
  bosh_agent_password: $(pwgen)
  bosh_registry_password: $(pwgen)
  bosh_redis_password: $(pwgen)
  bosh_blobstore_director_password: $(pwgen)
  bosh_hm_director_password: $(pwgen)
  bosh_admin_password: $(pwgen)
EOF
