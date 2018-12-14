manifest/cf-manifest/operations.d
=================================

List of [BOSH opsfiles](https://bosh.io/docs/cli-ops-files/)
that will be automatically applied to the
[cf-deployment.yml](https://github.com/cloudfoundry/cf-deployment/blob/master/cf-deployment.yml)
base manifest.

These opsfile implement all the default feature and customisations that
we add in our CF deployment.

Any file following the convention `[0-9][0-9][0-9]-*.yml` will be added
automatically, and applied in order.


We try to follow this convention to number the files:

    - 000-100 bosh related stuff
    - 100-300 global changes to cf-deployment
    - 300-500 job/service specific changes to cf-deployment
    - 500-700 new features: additions to base CF
    - 700-900 new features: additional instance groups (e.g. brokers)
    - 900 things that need to run at last (e.g. cert rotation and prune)

Any special file that would be added optionally (e.g. OAuth) shall
be in the `../operations/*` directory.
