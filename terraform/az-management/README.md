# AZ Management

If there is ever an occurrence of AWS losing a single AZ, we'd like to have a
way of disabling that AZ programmatically, to ensure our CF and BOSH stop any
traffic and scheduling onto the damaged AZ.

## How to run

The following will disable an AZ:

```
terraform apply
```

The following will re-enable an AZ:

```
terraform destroy
```

This is only intended to be run through Concourse job. However, it may be
necessary to run by hand, if we happen to lose an AZ that the Concourse is
running on.
