# Data Migration Service Setup

## Overview

There are a few parts to the setting up of DMS. The account running the DMS terraform needs to have certain AWS service access rights. Configure the VPC peering that is required for the DMS pipelining to other AWS accounts. Set the [create-cloudfoundry] pipeline against the appropriate environment. Make a note of any peering ids that are required. Setup the DMS configuration file named after the environment. Run the `create-cloudfoundry` job called `dms-terraform`.

## Setup Steps

1. There may be [vpc peerings](../terraform/vpc-peering) required. Ensure that they are setup before progressing further. Config files exist under [terraform](../terraform) folder and have a `vpc_peering.json` suffix, like [prod.vpc_peering.json](../terraform/prod.vpc_peering.json).
2. Secrets Manager has to hold the secrets for both the source and target databases. These secrets need to be accessible by the concourse AWS account for this terraform to work. The secret names must also be noted so that they can be used in the DMS configuration json file. The secrets file must contain the secrets shown in the example below:
    ```yaml
    {
        "host": "string, holding the the DNS or the IP of the source/target RDS instance",
        "password": "string, the master password of the RDS db",
        "port": "integer, the port on which the RDS db is listening. Posibly on standard Postgresql pord 5432",
        "username": "string, the admin username for the RDS db",
        "database_name": "string, the db name to be migrated",
        "engine_name": "string, in our case the value should be `postgres`"
    }
   ```
3.  Within the terraform directory in this repo a `${env}.dms.json` file is required to provide the DMS terraform with extra configuration. The detail required is shown in the example below:
    ```yaml
    [
        {
            "name": "string, a meaningful migration name e.g. account-migration",
            "source_secret_name": "string, a secret name used in AWS to hold the source database credentials as shown above",
            "target_secret_name": "string, similar to `source_secret_name` for the target database",
            "instance": {
                "allocated_storage": "integer, a storage size in Mb for the DMS replication instance. Make sure it is big enough.",
                "allow_major_version_upgrade": "boolean, preferably false",
                "apply_immediately": "boolean, depending on the situation. true for most cases",
                "auto_minor_version_upgrade": "boolean, true for most cases",
                "availability_zone": "string, the availability zone the instance will reside. Use availability zone AWS formated strings like `eu-west-1a`",
                "engine_version": "string, check the engine version from the DMS documentation: `3.4.7`",
                "multi_az": "boolean, false for single instance true for multiple",
                "preferred_maintenance_window": "string that looks like this: `sun:10:30-sun:14:30`",
                "publicly_accessible": "boolean, `false` always unless instructed otherwise",
                "replication_instance_class": "string, dms instances classes look like this: `dms.t3.small`"
            },
            "task": {
                "migration_type": "string, most of the cases are covered with `full-load-and-cdc` for full copy and contineous migration. Otherwise `full-load` to just move the db across."
            },
            "vpc_peering": {
                "cidr_block": "string, a cird block like `172.1.0.0/16`",
                "vpc_peering_connection_id": "string, a peering connection id as shown in AWS console: `pcx-xxxxxxxxxxxxxxxx`"
            }
        },
            ...
    ]
    ```
    The "instance" in the json above refers to the Replication Instance and the "task" refers to the Replication Task.
4.  Set the [create-cloudfoundry] pipeline if you haven't already, against the appropriate environment.

[create-cloudfoundry]: ../concourse/pipelines/create-cloudfoundry.yml