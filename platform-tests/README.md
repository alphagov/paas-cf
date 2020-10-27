# Platform acceptance tests

These are acceptance tests for our CF deployment that are run in
addition to the [upstream acceptance
tests](https://github.com/cloudfoundry/cf-acceptance-tests). These are
automatically run from the concourse pipeline after the platform has been
deployed.

## Dependencies

The tests have the following dependencies:
* a recent [Go compiler](https://golang.org/dl/)
* the [CF CLI](https://github.com/cloudfoundry/cli#downloads).
* `curl`
* [`godep`](https://github.com/tools/godep)

When running on concourse, these use our [cf-acceptance-tests
container](https://github.com/orgs/alphagov/packages/container/package/paas%2Fcf-acceptance-tests).

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
  "test_password": "meowmeow",
  "skip_ssl_validation": true,
  "use_http": false
}
