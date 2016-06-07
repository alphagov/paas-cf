#!/bin/sh
set -eu

export AWS_DEFAULT_REGION=eu-west-1

DB_INSTANCES=$(
  aws rds describe-db-instances --output text \
  --query "DBInstances[?starts_with(DBInstanceIdentifier, 'rdsbroker-') && ends_with(DBParameterGroups[0].DBParameterGroupName, '${DEPLOY_ENV}') ] | [*].DBInstanceIdentifier"
)

secret=$(awk '/rds_broker_master_password_seed/ { print $2 }' cf-secrets/cf-secrets.yml)

for instance in $DB_INSTANCES; do
  guuid=${instance##rdsbroker-}
  new_password=$(printf "%s" "${secret}${guuid}" | openssl dgst -md5 -binary | openssl enc -base64 | tr '+/' '-_')
  aws rds modify-db-instance --db-instance-identifier "${instance}" --master-user-password "${new_password}"
done
