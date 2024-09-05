#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it to proceed."
    exit 1
fi

# Define the CA certificate identifier to filter by
prev_ca_certificate="rds-ca-2019"
outdated_rds_instances=$(aws rds describe-db-instances | jq -r '.DBInstances[] | select(.CACertificateIdentifier == "'"$prev_ca_certificate"'")')
echo $outdated_rds_instances
outdated_rds_count=$(echo "$outdated_rds_instances" | wc -l)
echo "Total not updated RDS instances: $outdated_rds_count"


updated_ca_certificate="rds-ca-rsa2048-g1"

# Get all RDS instances with the specified CA certificate identifier
updated_rds_instances=$(aws rds describe-db-instances | jq -r '.DBInstances[] | select(.CACertificateIdentifier == "'"$updated_ca_certificate"'") | .DBInstanceIdentifier')
updated_rds_count=$(echo "$updated_rds_instances" | wc -l)
echo "Total updated RDS instances: $updated_rds_count"


# Define the date to compare against
target_date="2023-07-30T00:00:00Z"

# Get all RDS instances
rds_instances=$(aws rds describe-db-instances | jq -r '.DBInstances[] | select(.PendingModifiedValues.NextMaintenanceWindowStartTime > "'"$target_date"'") | .DBInstanceIdentifier')

#echo $rds_rds_instances

rds_count=$(echo "$rds_instances" | wc -l)
echo "Total RDS instances with next maintenance window after $target_date: $rds_count"