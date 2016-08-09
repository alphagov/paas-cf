#!/bin/bash

set -eux

SCRIPT_NAME="$0"
export AWS_DEFAULT_REGION=eu-west-1

abort() {
  echo "$@" 1>&2
  exit 1
}

usage() {
  cat <<EOF
This script will restore a RDS backup using AWS restore point in time
or recover from a snapshot, creating a new service in the current organisation
with that DB.

The script will:
 1. Create a service instance using cf-cli
 2. Throw away the RDS instance created by cf-cli, but keep the reference in CF.
 3. Restore the backup to a new RDS instace
 4. Rename the restored instance to the name created in 1, and deleted in 2.

In order for this script to work you require:
 * Have cf-cli installed.
 * Login into cf as a OrgManager or Admin user.
 * Target the organisation where the services reside and must be restored.
 * Have aws-cli installed.
 * Export the AWS credentials for the AWS account that hosts the RDS instances

Usage:

$SCRIPT_NAME point-in-time <from-service-instance> <to-service-instance> <time-stamp>

Will restore a DB to a point in time. The origin DB must exists.

 * from-service-instance: CF DB instance to restore from.
 * to-service-instance: Name of the new service created
 * time-stamp: time to restore from, in any format the "date" command supportS:
   * "15 minutes ago"
   * "yesterday"
   * "2016-08-09T09:07:16+0000"

$SCRIPT_NAME snapshot <aws-snapshot-name> <to-service-instance> <plan>

Will restore a DB based on a given snapshot. Will create a service with the given plan.

 * from-service-instance: CF DB instance to restore from.
 * to-service-instance: Name of the new service created
 * plan: plan to use from the marketplace of postgres
EOF
}

parse_params() {
  # TODO
  RDS_BROKER_MASTER_PASSWORD_SEED="mysecret"

  FROM_INSTANCE_GUID=""
  SERVICE_PLAN=""

  RESTORE_TYPE=${1:-}
  case "$RESTORE_TYPE" in
    point-in-time)
      shift
      if [ $# -lt 3 ]; then
        usage
      fi
      FROM_INSTANCE_NAME="$1"
      TO_INSTANCE_NAME="$2"
      RESTORE_DATE_PARAM="$3"

      # Value must be a time in Universal Coordinated Time (UTC) format
      RESTORE_DATE="$(date -d "${RESTORE_DATE_PARAM}" -u --iso-8601=seconds)" # Parse the date and output iso-8601

      if ! INSTANCE_INFO="$(cf service "${FROM_INSTANCE_NAME}")"; then
        abort "Unable to get original service instance ${FROM_INSTANCE_NAME} info: ${INSTANCE_INFO}"
      fi
      if ! FROM_INSTANCE_GUID="$(cf service "${FROM_INSTANCE_NAME}" --guid)"; then
        abort "Unable to get original service instance GUID: ${FROM_INSTANCE_GUID}"
      fi
      SERVICE_TYPE="$(echo "${INSTANCE_INFO}" | sed -n 's/^Service: //p')"
      SERVICE_PLAN="$(echo "${INSTANCE_INFO}" | sed -n 's/^Plan: //p')"
      FROM_RDS_INSTANCE_NAME="rdsbroker-${FROM_INSTANCE_GUID}"
    ;;
    snapshot)
      shift
      if [ $# -lt 3 ]; then
        usage
      fi
      FROM_RDS_SNAPSHOT_NAME="$1"
      TO_INSTANCE_NAME="$2"
      SERVICE_PLAN="$3"
      SERVICE_TYPE="postgres"
    ;;
    *)
      usage
    ;;
  esac

  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
}

extract_existing_instance_info() {
  local instance_name="$1"
  instance_info_json=/tmp/instance_info.$$.json
  trap 'rm -f "${instance_info_json}"' EXIT INT TERM

  echo "Extracting RDS settings of temporary RDS instance ${instance_name}..."
  aws rds describe-db-instances \
    --region "${AWS_DEFAULT_REGION}" \
    --db-instance-identifier "${instance_name}" > "${instance_info_json}"
  DESIRED_DB_INSTANCE_CLASS="$(jq -r '.DBInstances[0].DBInstanceClass' < ${instance_info_json})"
  DESIRED_DB_SUBNET_GROUP_NAME="$(jq -r '.DBInstances[0].DBSubnetGroup.DBSubnetGroupName' < ${instance_info_json})"
  DESIRED_ENGINE="$(jq -r '.DBInstances[0].Engine' < ${instance_info_json})"
  DESIRED_OPTION_GROUP_NAME="$(jq -r '.DBInstances[0].OptionGroupMemberships[0].OptionGroupName' < ${instance_info_json})"
  DESIRED_STORAGE_TYPE="$(jq -r '.DBInstances[0].StorageType' < ${instance_info_json})"
  DESIRED_DB_PARAMETER_GROUP_NAME="$(jq -r '.DBInstances[0].DBParameterGroups[0].DBParameterGroupName' < ${instance_info_json})"
  DESIRED_VPC_SECURITY_GROUP_IDS="$(jq -r '.DBInstances[0].VpcSecurityGroups | map(.VpcSecurityGroupId) | join(" ")' < ${instance_info_json})"
  DESIRED_BACKUP_RETENTION_PERIOD="$(jq -r '.DBInstances[0].BackupRetentionPeriod' < ${instance_info_json})"

  DESIRED_TAGS=$(
    aws rds list-tags-for-resource \
      --region "${AWS_DEFAULT_REGION}" \
      --resource-name "arn:aws:rds:${AWS_DEFAULT_REGION}:${AWS_ACCOUNT_ID}:db:${instance_name}" \
      --query TagList
  )

  rm -f "${instance_info_json}"

  # Print the settings
  ( set -o posix ; set ) | grep DESIRED | sed 's/^/    /'
}

create_new_cf_instance() {
  echo "Creating new instance $TO_INSTANCE_NAME in Cloudfoundry..."
  if cf service "${TO_INSTANCE_NAME}" > /dev/null; then
    abort "ERROR: Service ${TO_INSTANCE_NAME} already exists, aborting..."
  fi
  cf create-service "${SERVICE_TYPE}" "${SERVICE_PLAN}" "${TO_INSTANCE_NAME}"

  if ! TO_INSTANCE_GUID=$(cf service "${TO_INSTANCE_NAME}" --guid); then
    abort "Unable to get new service instance GUID: ${TO_INSTANCE_GUID}"
  fi

  TO_RDS_INSTANCE_NAME="rdsbroker-${TO_INSTANCE_GUID}"

  # Extract the attributes (Security groups, DB parameters, etc.) from the recently created DB.
  # This way we don't need to parse the settings from YAMLs
  extract_existing_instance_info "${TO_RDS_INSTANCE_NAME}"

  echo "Deleting temporary AWS RDS instance that has been just created: ${TO_RDS_INSTANCE_NAME}..."
  aws rds delete-db-instance \
    --region "${AWS_DEFAULT_REGION}" \
    --db-instance-identifier "${TO_RDS_INSTANCE_NAME}" \
    --skip-final-snapshot > /dev/null
}

trigger_restore_instance() {
  case "$RESTORE_TYPE" in
    point-in-time)
      echo "Restoring RDS instance ${FROM_RDS_INSTANCE_NAME} into ${TO_RDS_INSTANCE_NAME}-restore from point in time ${RESTORE_DATE}"
      aws rds restore-db-instance-to-point-in-time \
        --region "${AWS_DEFAULT_REGION}" \
        --source-db-instance-identifier "${FROM_RDS_INSTANCE_NAME}" \
        --target-db-instance-identifier "${TO_RDS_INSTANCE_NAME}-restore" \
        --restore-time "${RESTORE_DATE}" \
        --db-instance-class "${DESIRED_DB_INSTANCE_CLASS}" \
        --db-subnet-group-name "${DESIRED_DB_SUBNET_GROUP_NAME}" \
        --copy-tags-to-snapshot \
        --engine "${DESIRED_ENGINE}" \
        --option-group-name "${DESIRED_OPTION_GROUP_NAME}" \
        --storage-type "${DESIRED_STORAGE_TYPE}" > /dev/null
    ;;
    snapshot)
      echo "Restoring snapshot ${FROM_RDS_SNAPSHOT_NAME} into ${TO_RDS_INSTANCE_NAME}-restore"
      aws rds restore-db-instance-from-db-snapshot \
        --db-snapshot-identifier "${FROM_RDS_SNAPSHOT_NAME}" \
        --db-instance-identifier "${TO_RDS_INSTANCE_NAME}-restore" \
        --db-instance-class "${DESIRED_DB_INSTANCE_CLASS}" \
        --db-subnet-group-name "${DESIRED_DB_SUBNET_GROUP_NAME}" \
        --copy-tags-to-snapshot \
        --engine "${DESIRED_ENGINE}" \
        --option-group-name "${DESIRED_OPTION_GROUP_NAME}" \
        --storage-type "${DESIRED_STORAGE_TYPE}" > /dev/null
    ;;
    *)
      abort "not implemented"
    ;;
  esac
}

modify_new_instance() {
  # We must reset the master password
  TO_MASTER_PASSWORD=$(
    echo -n "${RDS_BROKER_MASTER_PASSWORD_SEED}${TO_INSTANCE_GUID}" | \
      openssl dgst -md5 -binary | \
      openssl enc -base64 | \
      tr '+/' '-_'
    )

  echo "Applying tags to ${TO_RDS_INSTANCE_NAME}-restore to match desired ones"
  aws rds add-tags-to-resource \
    --region "${AWS_DEFAULT_REGION}" \
    --resource-name "arn:aws:rds:${AWS_DEFAULT_REGION}:${AWS_ACCOUNT_ID}:db:${TO_RDS_INSTANCE_NAME}-restore" \
    --tags "${DESIRED_TAGS}"

  echo "Modifying AWS settings of ${TO_RDS_INSTANCE_NAME}-restore to match desired ones"
  aws rds modify-db-instance \
    --region "${AWS_DEFAULT_REGION}" \
    --db-instance-identifier "${TO_RDS_INSTANCE_NAME}-restore" \
    --new-db-instance-identifier  "${TO_RDS_INSTANCE_NAME}" \
    --db-parameter-group-name "${DESIRED_DB_PARAMETER_GROUP_NAME}" \
    --vpc-security-group-ids "${DESIRED_VPC_SECURITY_GROUP_IDS}" \
    --backup-retention-period "${DESIRED_BACKUP_RETENTION_PERIOD}" \
    --master-user-password "${TO_MASTER_PASSWORD}" \
    --apply-immediately
}

get_instance_status() {
  aws rds describe-db-instances \
    --region "${AWS_DEFAULT_REGION}" \
    --db-instance-identifier "$1" \
    --query 'DBInstances[0].DBInstanceStatus'
}

wait_for_rds_instance_available() {
  echo -n "Waiting for RDS instance $1 to be available..."
  while true; do
    if output=$(get_instance_status "$1" 2>&1); then
      if echo "$output" | grep -q available; then
        break
      else
        echo -n .;
        sleep 5
      fi
    else
      echo
      abort "Error: $output"
    fi
  done
  echo
}

wait_for_rds_instance_deleted() {
  echo -n "Waiting for RDS instance $1 to be deleted..."
  while true; do
    if ! output=$(get_instance_status "$1" 2>&1); then
      if echo "$output" | grep -q DBInstanceNotFound; then
        break
      else
        echo
        abort "Error: $output"
      fi
    fi
    echo -n .
    sleep 5
  done
  echo
}


parse_params "$@"

# Will create a CF instance, and the RDS one will be being deleted in background
create_new_cf_instance
# Will trigger a backup in background
trigger_restore_instance

wait_for_rds_instance_available "${TO_RDS_INSTANCE_NAME}-restore"
wait_for_rds_instance_deleted "${TO_RDS_INSTANCE_NAME}"

modify_new_instance

echo "Done :)"

