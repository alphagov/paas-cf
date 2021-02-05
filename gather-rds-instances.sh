#!/usr/bin/env bash

aws rds describe-db-instances \
  --filters 'Name=engine,Values=postgres' \
| jq -r '([.DBInstances[] | select(.EngineVersion | startswith("12") | not) | select(.DBInstanceIdentifier | startswith("rdsbroker")) | select(.DBInstanceStatus == "available") | {"Hostname": .Endpoint.Address, "Username": .MasterUsername, "Id": .DBInstanceIdentifier, "DBName": .DBName }]) // []'
