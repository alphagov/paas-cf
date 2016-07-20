#!/bin/sh
set -eu

if [ $# -lt 2 ]; then
  echo "Usage $0 <deploy_env> <retention_in_days>"
  exit 1
fi

DEPLOY_ENV=$1
RETENTION=$2

export AWS_DEFAULT_REGION=eu-west-1

echo "Changing retention period to ${RETENTION} for RDS Broker instances:"

account_id=$(aws sts get-caller-identity --output text --query Account)
if [ -z "$account_id" ]; then
  echo "Unable to retrieve the account id"
  exit 1
fi

echo "Retrieving all rdsbroker-* RDS instances for Account ID: ${account_id}"

DB_INSTANCES=$(
  aws rds describe-db-instances --output text \
  --query "DBInstances[?starts_with(DBInstanceIdentifier, 'rdsbroker-')] | [*].DBInstanceIdentifier"
)


echo "Filtering instances of environment '${DEPLOY_ENV}' (tag[Broker Name] == '${DEPLOY_ENV}')"
ENV_DB_INSTANCES=""
for instance in $DB_INSTANCES; do
    if aws rds list-tags-for-resource \
        --output=text --region eu-west-1 \
        --resource-name "arn:aws:rds:eu-west-1:${account_id}:db:${instance}" \
        --query "TagList[?Key=='Broker Name' && Value=='${DEPLOY_ENV}']" \
        | grep -q 'Broker Name'; then
        ENV_DB_INSTANCES="$instance ${ENV_DB_INSTANCES}"
    fi
done

for instance in $ENV_DB_INSTANCES; do
  echo "Setting $instance retention to ${RETENTION} days..."
  aws rds modify-db-instance \
    --db-instance-identifier "${instance}" \
    --backup-retention-period "${RETENTION}" \
    --no-apply-immediately > /dev/null
done

echo Done
