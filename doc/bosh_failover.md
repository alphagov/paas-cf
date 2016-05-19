# BOSH failover

In case of availability zone failure, BOSH can be recreated in another AZ. The state
is stored in RDS and S3 so the new BOSH can take over straight away.

## Failover process

There are 3 AZs available:

* eu-west-1a
* eu-west-1b
* eu-west-1c

The default one is *eu-west-1a*. To deploy BOSH to another AZ, set the environment
variable `BOSH_AZ` before uploading the pipelines. Ex:

```
BOSH_AZ='eu-west-1b' make prod pipelines
```

Run the `create-bosh-cloudfoundry` pipeline, it should deploy a new BOSH, then run
`cf-deploy` successfully. Watch for `bosh-tests` that will run basic BOSH validation tests.

## Warning

* You shouldn't run 2 instances of BOSH at the same time as this may cause issues. For
example the bosh agents may remain connected to the old BOSH and the new BOSH may not
see what it expects.
To avoid this issue, kill the first BOSH or make sure it doesn't come back alive.

* Once the AZ has been changed from default, the `BOSH_AZ` environment variable should
always be set to the new AZ when uploading pipelines manually. Otherwise a new BOSH will
be recreated in the default AZ.
