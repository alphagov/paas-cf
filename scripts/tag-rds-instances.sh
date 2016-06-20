#!/bin/sh
set -eu

account=$(aws sts get-caller-identity --query Account | tr -d \")

DB_INSTANCES=$(
  aws rds describe-db-instances --output text \
  --query "DBInstances[?starts_with(DBInstanceIdentifier, 'rdsbroker-') && ends_with(DBParameterGroups[0].DBParameterGroupName, '${DEPLOY_ENV}') ] | [*].DBInstanceIdentifier"
)

for instance in $DB_INSTANCES; do
  # shellcheck disable=SC2140
  aws --region "${AWS_DEFAULT_REGION}" rds add-tags-to-resource --resource-name arn:aws:rds:"${AWS_DEFAULT_REGION}":"${account}":db:"${instance}" --tags "Key=Broker Name,Value=${DEPLOY_ENV}"
  echo "Tagged $instance with 'Broker Name=${DEPLOY_ENV}' tag."
done
