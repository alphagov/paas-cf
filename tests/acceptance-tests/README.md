# Custom acceptance tests

These are custom acceptance tests for the CF deployment that are run in
addition to the [upstream acceptance
tests](https://github.com/cloudfoundry/cf-acceptance-tests). These are
automatically run from the deploy-cloudfoundry concourse pipeline after the
concourse deploy.

## Dependencies

The tests have the following dependencies:
* a recent [Go compiler](https://golang.org/dl/)
* the [CF CLI](https://github.com/cloudfoundry/cli#downloads).
* `curl`
* [`godep`](https://github.com/tools/godep)

When running on concourse, these use our [cf-cli
container](https://hub.docker.com/r/governmentpaas/cf-cli/).

## Running the tests

You must set an environment variable `$CONFIG` which points to a JSON file that
contains several pieces of data that will be used to configure the acceptance
tests, e.g. telling the tests how to target your running Cloud Foundry
deployment.

Example:
```json
{
  "api": "api.foo.cf.example.com",
  "admin_user": "admin",
  "admin_password": "secret",
  "apps_domain": "foo.cf-apps.example.com",
  "skip_ssl_validation": true,
  "use_http": false
}
```

Run the tests using the `run_tests.sh` script.
