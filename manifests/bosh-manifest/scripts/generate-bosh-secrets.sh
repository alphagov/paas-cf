#!/bin/sh

simplepass() {
  pwgen -1s 12
}

cat <<EOF
---
secrets:
  bosh_postgres_password: $(simplepass)
  bosh_nats_password: $(simplepass)
  bosh_agent_password: $(simplepass)
  bosh_registry_password: $(simplepass)
  bosh_redis_password: $(simplepass)
  bosh_blobstore_director_password: $(simplepass)
  bosh_hm_director_password: $(simplepass)
  bosh_admin_password: $(simplepass)
EOF
