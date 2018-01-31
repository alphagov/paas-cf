#!/bin/bash

set -eu

if  [ "${DISABLE_CF_ACCEPTANCE_TESTS:-}" = "true" ]; then
  echo "WARNING: The acceptance tests have been disabled. Unset DISABLE_CF_ACCEPTANCE_TESTS when uploading the pipelines to enable them. You can still hijack this container to run them manually, but you must update the admin user in ./test-config/config.json."
  exit 0
fi

SLEEPTIME=90
NODES=5
SKIP_REGEX='routing.API|allows\spreviously-blocked\sip|Adding\sa\swildcard\sroute\sto\sa\sdomain|forwards\sapp\smessages\sto\sregistered\ssyslog\sdrains|when\sapp\shas\smultiple\sports\smapped'
SLOW_SPEC_THRESHOLD=120

export CONFIG
CONFIG="$(pwd)/test-config/config.json"

./paas-cf/concourse/scripts/import_bosh_ca.sh

echo "Sleeping for ${SLEEPTIME} seconds..."
for i in $(seq $SLEEPTIME 1); do echo -ne "$i"'\r'; sleep 1; done; echo

GOPATH="${GOPATH}:$(pwd)"
export GOPATH

echo "Starting acceptace tests"
cd src/github.com/cloudfoundry/cf-acceptance-tests
./bin/test \
  -keepGoing \
  -randomizeAllSpecs \
  -skipPackage=helpers \
  -skip=${SKIP_REGEX} \
  -slowSpecThreshold=${SLOW_SPEC_THRESHOLD} \
  -nodes="${NODES}"
