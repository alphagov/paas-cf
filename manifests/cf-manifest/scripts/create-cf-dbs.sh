#!/bin/sh
set -e

# TODO: Implement this in terraform https://www.terraform.io/docs/providers/postgresql/index.html

# Check environment variables
export PGPASSWORD=${TF_VAR_secrets_cf_db_master_password:?}
api_pass=${TF_VAR_external_cc_database_password:?}
uaa_pass=${TF_VAR_external_uaa_database_password:?}
bbs_pass=${TF_VAR_external_bbs_database_password:?}
locket_pass=${TF_VAR_external_locket_database_password:?}
network_connectivity_pass=${TF_VAR_external_network_connectivity_database_password:?}
network_policy_pass=${TF_VAR_external_policy_server_database_password:?}
db_address=${TF_VAR_cf_db_address:?}

# See: https://github.com/koalaman/shellcheck/wiki/SC2086#exceptions
psql_adm() { psql -h "${db_address}" -U dbadmin "$@"; }

# Create roles
psql_adm -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname = 'api'" \
  | grep -q 'api' || psql_adm -d postgres -c "CREATE USER api WITH ROLE dbadmin"


psql_adm -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname = 'uaa'" \
  | grep -q 'uaa' || psql_adm -d postgres -c "CREATE USER uaa WITH ROLE dbadmin"

psql_adm -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname = 'bbs'" \
  | grep -q 'bbs' || psql_adm -d postgres -c "CREATE USER bbs WITH ROLE dbadmin"

psql_adm -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname = 'locket'" \
  | grep -q 'locket' || psql_adm -d postgres -c "CREATE USER locket WITH ROLE dbadmin"

psql_adm -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname = 'network_connectivity'" \
  | grep -q 'network_connectivity' || psql_adm -d postgres -c "CREATE USER network_connectivity WITH ROLE dbadmin"

psql_adm -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname = 'network_policy'" \
  | grep -q 'network_policy' || psql_adm -d postgres -c "CREATE USER network_policy WITH ROLE dbadmin"

# Always update passwords
psql_adm -d postgres -c "ALTER USER api WITH PASSWORD '${api_pass}'"
psql_adm -d postgres -c "ALTER USER uaa WITH PASSWORD '${uaa_pass}'"
psql_adm -d postgres -c "ALTER USER bbs WITH PASSWORD '${bbs_pass}'"
psql_adm -d postgres -c "ALTER USER locket WITH PASSWORD '${locket_pass}'"
psql_adm -d postgres -c "ALTER USER network_connectivity WITH PASSWORD '${network_connectivity_pass}'"
psql_adm -d postgres -c "ALTER USER network_policy WITH PASSWORD '${network_policy_pass}'"

for db in api uaa bbs locket network_connectivity network_policy; do

  # Create database
  psql_adm -d postgres -l | grep -q " ${db} " || \
    psql_adm -d postgres -c "CREATE DATABASE ${db} OWNER ${db}"

  # Enable extensions
  for ext in citext pgcrypto pg_stat_statements; do
    psql_adm -d "${db}" -c "CREATE EXTENSION IF NOT EXISTS ${ext}"
  done

done
