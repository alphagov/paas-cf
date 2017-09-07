[![Build Status](https://travis-ci.org/cloudfoundry-incubator/cf-test-helpers.svg)](https://travis-ci.org/cloudfoundry-incubator/cf-test-helpers)
cf-test-helpers
===============

Go utilities for running tests against Cloud Foundry

Included Tools:
- Execute [CF CLI](https://github.com/cloudfoundry/cli) commands
  - Isolated user contexts for wrapping CF commands
  - Curl CF endpoints
- Random user name generator
- Thin wrapper around curl (in `cf-test-helpers/runner`)
