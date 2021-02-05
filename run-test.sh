#! /usr/bin/env bash
set -euo pipefail

PASSWORD=$(openssl rand -base64 12)
INSTANCE_IDENTIFIER="andyhunt-delete-by-0301-postgis-upgrade-$(date +%s)"

echo "Instance identifier: ${INSTANCE_IDENTIFIER}"
echo "Password: ${PASSWORD}"

echo "Creating database"
aws rds create-db-instance \
    --db-instance-identifier ${INSTANCE_IDENTIFIER} \
    --db-name testdb \
    --db-instance-class db.t2.small \
    --engine postgres \
    --engine-version 9.5 \
    --master-username test_postgres_admin \
    --master-user-password "${PASSWORD}" \
    --db-parameter-group-name default.postgres9.5 \
    --allocated-storage 10 \
    >/dev/null

echo "Waiting for database to be available ..."
aws rds wait db-instance-available \
    --db-instance-identifier ${INSTANCE_IDENTIFIER}

DB_HOST=$(aws rds describe-db-instances --db-instance-identifier ${INSTANCE_IDENTIFIER} | jq -r '.DBInstances[0].Endpoint.Address')

PGPASSWORD="${PASSWORD}" psql -h "${DB_HOST}" -U test_postgres_admin -c "CREATE EXTENSION postgis;" testdb
PGPASSWORD="${PASSWORD}" psql -h "${DB_HOST}" -U test_postgres_admin -f upgrade.pgsql testdb
PGPASSWORD="${PASSWORD}" psql -h "${DB_HOST}" -U test_postgres_admin -f check-version.pgsql testdb

./major-version-upgrades.sh ${INSTANCE_IDENTIFIER}
