#!/usr/bin/env bash

DATABASES_INPUT_FILE=$1
PASSWORD_GENERATOR_BINARY=${PASSWORD_GENERATOR_BINARY:-./rds-broker-passwd}
PSQL=${PSQL:-/home/vcap/deps/0/apt/usr/lib/postgresql/10/bin/psql}

# Doesn't seem to work on MacOS (Darwin), but does work on Linux.
read -sp "Master database password seed: " MASTER_DB_PASSWORD_SEED

echo ""
echo "-----"
echo ""

# Read inputs
for entry in $(jq -rc '.[]' $DATABASES_INPUT_FILE); do
    HOST=$(echo $entry | jq -r '.Hostname')
    USERNAME=$(echo $entry | jq -r '.Username')
    ID=$(echo $entry | jq -r '.Id' | cut -d'-' -f 2-)
    DB=$(echo $entry | jq -r '.DBName')
    PASSWORD=$(printf "${MASTER_DB_PASSWORD_SEED}\n${ID}" | ${PASSWORD_GENERATOR_BINARY} | tail -n1)


    echo "Beginning ${ID}"

    echo "Connecting to ${ID}. Purpose: UPGRADE"
    PGPASSWORD=${PASSWORD} $PSQL -h "${HOST}" -U ${USERNAME} -f upgrade.pgsql ${DB}
    echo "Connecting to ${ID}. Purpose: CHECK VERSION"
    PGPASSWORD=${PASSWORD} $PSQL -h "${HOST}" -U ${USERNAME} -f check-version.pgsql ${DB}
    echo "Done attempted upgrade for ${ID} "
done;

echo "DONE"
