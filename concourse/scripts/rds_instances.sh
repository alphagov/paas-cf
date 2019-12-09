#!/bin/bash

set -euo pipefail

ACTION=$1
CMD=""
STATE_BEFORE=""
STATE_AFTER=""

case $ACTION in
  start)
    CMD=start-db-instance
    STATE_BEFORE="stopped"
    STATE_AFTER="available"
  ;;
  stop)
    CMD=stop-db-instance
    STATE_BEFORE="available"
    STATE_AFTER="stopped"
  ;;
  *)
    echo "Action '${ACTION}' is not supported... Please try 'start' or 'stop' instead."
    exit 1
  ;;
esac

get_instance_ids_with_status() {
  aws rds describe-db-instances \
    --query "DBInstances[?DBSubnetGroup.VpcId == \`${vpc_ids}\` \
             && DBInstanceStatus == \`${1}\` \
             && MultiAZ == \`false\` \
             && DBInstanceIdentifier != \`${DEPLOY_ENV}-bosh\` \
             && DBInstanceIdentifier != \`${DEPLOY_ENV}-concourse\`].DBInstanceIdentifier" \
    --output text | tr '\t' '\n' | sort
}

# Obtain the VPC ID from the AWS API and make sure there is only one that we can
# use.
vpc_ids=$(
  aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=${DEPLOY_ENV}" \
    --query 'Vpcs[].VpcId' \
    --output text
)

vpc_ids_count=$(echo "${vpc_ids}" | awk '{print NF}')

if [ ! "${vpc_ids_count}" -eq 1 ]; then
  echo "Number of VPCs need to be exactly 1. Got: ${vpc_ids}"
  exit 1
fi

# Make a list of RDS Instances that are assigned to the specific VPC ID, are not
# MultiAZ and are/do not contain any replicas.
all_instance_ids=$(
  aws rds describe-db-instances \
    --query "DBInstances[?DBSubnetGroup.VpcId == \`${vpc_ids}\` \
             && MultiAZ == \`false\` \
             && DBInstanceIdentifier != \`${DEPLOY_ENV}-bosh\` \
             && DBInstanceIdentifier != \`${DEPLOY_ENV}-concourse\`].DBInstanceIdentifier" \
    --output text | tr '\t' '\n' | sort
)

# Make a sublist of RDS Instances that not in the desired state
instance_ids=$(get_instance_ids_with_status ${STATE_BEFORE})


for instance_id in $instance_ids; do
  aws rds "${CMD}" --db-instance-identifier "${instance_id}"
done

for _ in $(seq 1 20); do
  instance_ids_after=$(get_instance_ids_with_status ${STATE_AFTER})

  if [ "${all_instance_ids}" = "${instance_ids_after}" ]; then
    echo "All done. Happy days."
    exit 0
  fi

  echo "Waiting for the instances to ${ACTION}. Sleeping for 60 seconds..."

  sleep 60
done

echo "We have waited for too long. Nothing we can do. Check it out yourself..."
echo "${all_instance_ids}"
exit 1
