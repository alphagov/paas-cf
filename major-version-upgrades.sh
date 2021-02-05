#!/usr/bin/env bash

INSTANCE_IDENTIFIER=$1

echo "Trying to upgrade to 10"
aws rds modify-db-instance \
    --db-instance-identifier ${INSTANCE_IDENTIFIER} \
    --allow-major-version-upgrade \
    --engine-version 10 \
    --apply-immediately \
    >/dev/null

echo "Waiting for database to be available ..."
sleep 60
aws rds wait db-instance-available \
    --db-instance-identifier ${INSTANCE_IDENTIFIER}

echo "Trying to upgrade to 11"
aws rds modify-db-instance \
    --db-instance-identifier ${INSTANCE_IDENTIFIER} \
    --allow-major-version-upgrade \
    --engine-version 11 \
    --apply-immediately \
    >/dev/null

echo "Waiting for database to be available ..."
sleep 60
aws rds wait db-instance-available \
    --db-instance-identifier ${INSTANCE_IDENTIFIER}

echo "Trying to upgrade to 12"
aws rds modify-db-instance \
    --db-instance-identifier ${INSTANCE_IDENTIFIER} \
    --allow-major-version-upgrade \
    --engine-version 12 \
    --apply-immediately \
    >/dev/null

echo "Waiting for database to be available ..."
sleep 60
aws rds wait db-instance-available \
    --db-instance-identifier ${INSTANCE_IDENTIFIER}
