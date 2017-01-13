#!/bin/sh
set -e

# Check environment variables
export PGPASSWORD=${TF_VAR_secrets_cf_db_master_password:?}
api_pass=${TF_VAR_secrets_cf_db_api_password:?}
uaa_pass=${TF_VAR_secrets_cf_db_uaa_password:?}
bbs_pass=${TF_VAR_secrets_cf_db_bbs_password:?}
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

# Always update passwords
psql_adm -d postgres -c "ALTER USER api WITH PASSWORD '${api_pass}'"
psql_adm -d postgres -c "ALTER USER uaa WITH PASSWORD '${uaa_pass}'"
psql_adm -d postgres -c "ALTER USER bbs WITH PASSWORD '${bbs_pass}'"

for db in api uaa bbs; do

  # Create database
  psql_adm -d postgres -l | grep -q " ${db} " || \
    psql_adm -d postgres -c "CREATE DATABASE ${db} OWNER ${db}"

  # Enable extensions
  for ext in citext pgcrypto pg_stat_statements; do
    psql_adm -d "${db}" -c "CREATE EXTENSION IF NOT EXISTS ${ext}"
  done

done
