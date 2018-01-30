#!/bin/bash

set -eu

# FIXME: Remove this once https://github.com/cloudfoundry/cf-smoke-tests/pull/39 was merged
# and our CF release contains the fix.
(
  cd  "$(pwd)/cf-release/src/smoke-tests/"
  expected_commit_hash="1f219aa5cb8f3b6bfad312654ca66ff54d0cae5e"
  current_commit_hash="$(git log --pretty=format:'%H' -n 1)"
  if [ "${expected_commit_hash}" != "${current_commit_hash}" ]; then
    echo "ERROR: Current commit for smoke-tests is different than expected one: ${expected_commit_hash} != ${current_commit_hash}"
    echo "Double check if we still need to pull our branch"
    exit 1
  fi
  git remote add alphagov https://github.com/alphagov/paas-cf-smoke-tests.git
  git fetch alphagov
  git checkout fix_app_scale_tests_154477526
)

export CONFIG
CONFIG="$(pwd)/test-config/config.json"

./paas-cf/concourse/scripts/import_bosh_ca.sh

echo "Linking smoke-tests directory inside $GOPATH"
CF_GOPATH=/go/src/github.com/cloudfoundry
mkdir -p $CF_GOPATH
ln -s "$(pwd)/cf-release/src/smoke-tests" "${CF_GOPATH}/cf-smoke-tests"

echo "Linking test artifacts directory"
ln -s "$(pwd)/artifacts" /tmp/artifacts

cd "${CF_GOPATH}/cf-smoke-tests"

echo "Starting smoke tests"
./bin/test -keepGoing
