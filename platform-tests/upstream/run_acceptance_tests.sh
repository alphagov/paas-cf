#!/bin/bash

set -eu

if  [ "${DISABLE_CF_ACCEPTANCE_TESTS:-}" = "true" ]; then
  echo "WARNING: The acceptance tests have been disabled. Unset DISABLE_CF_ACCEPTANCE_TESTS when uploading the pipelines to enable them. You can still hijack this container to run them manually, but you must update the admin user in ./test-config/config.json."
  exit 0
fi

# FIXME: Remove this once we are deploying a version of cf-release
# that includes capi-release >= 1.38.0.
(
  cd  "$(pwd)/cf-release/src/github.com/cloudfoundry/cf-acceptance-tests/"
  expected_commit_hash="8965930580fb4808fd2b7d617eeed7f64b5ec2bb"
  current_commit_hash="$(git log --pretty=format:'%H' -n 1)"
  if [ "${expected_commit_hash}" != "${current_commit_hash}" ]; then
    echo "ERROR: Current commit for cf-acceptance-test is different than expected one: ${expected_commit_hash} != ${current_commit_hash}"
    echo "Double check if we still need to pull our branch"
    exit 1
  fi
  git remote add alphagov https://github.com/alphagov/paas-cf-acceptance-tests.git
  git fetch alphagov
  git checkout bugfix/backport_for_capi_1.38.0
)


SLEEPTIME=90
NODES=5
SKIP_REGEX='routing.API|allows\spreviously-blocked\sip|Adding\sa\swildcard\sroute\sto\sa\sdomain|forwards\sapp\smessages\sto\sregistered\ssyslog\sdrains|when\sapp\shas\smultiple\sports\smapped'
SLOW_SPEC_THRESHOLD=120

export CONFIG
CONFIG="$(pwd)/test-config/config.json"

./paas-cf/concourse/scripts/import_bosh_ca.sh

echo "Linking acceptance-tests directory inside $GOPATH"
CF_GOPATH=/go/src/github.com/cloudfoundry
mkdir -p $CF_GOPATH
ln -s "$(pwd)/cf-release/src/github.com/cloudfoundry/cf-acceptance-tests" "${CF_GOPATH}/cf-acceptance-tests"

echo "Linking test artifacts directory"
ln -s "$(pwd)/artifacts" /tmp/artifacts

echo "Sleeping for ${SLEEPTIME} seconds..."
for i in $(seq $SLEEPTIME 1); do echo -ne "$i"'\r'; sleep 1; done; echo

cd "${CF_GOPATH}/cf-acceptance-tests"

echo "Starting acceptace tests"
./bin/test \
  -keepGoing \
  -randomizeAllSpecs \
  -skipPackage=helpers \
  -skip=${SKIP_REGEX} \
  -slowSpecThreshold=${SLOW_SPEC_THRESHOLD} \
  -nodes="${NODES}"
