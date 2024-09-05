#!/bin/bash

NEW_CA_CERTIFICATE_IDENTIFIER="rds-ca-rsa2048-g1"

if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it to proceed."
    exit 1
fi

rds_instances=$(aws rds describe-db-instances | jq -r '.DBInstances[].DBInstanceIdentifier')

rds_count=$(echo "$rds_instances" | wc -l)
echo "Total RDS instances to update: $rds_count"

for instance_name in $rds_instances; do

    echo "Updating certificate for DB instance: $instance_name"

    aws rds modify-db-instance \
        --db-instance-identifier $instance_name \
        --ca-certificate-identifier $NEW_CA_CERTIFICATE_IDENTIFIER \
        --apply-immediately
    if [ $? -eq 0 ]; then
        echo "Successfully updated certificates for instance: $instance_name"
    else
        echo "Failed to update certificates for instance: $instance_name"
    fi
done

echo "Certificate update process completed."