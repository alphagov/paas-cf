#!/bin/bash

set -eu

if  [ "${DISABLE_CF_ACCEPTANCE_TESTS:-}" = "true" ]; then
  echo "WARNING: The acceptance tests have been disabled. Unset DISABLE_CF_ACCEPTANCE_TESTS when uploading the pipelines to enable them. You can still hijack this container to run them manually, but you must update the admin user in ./test-config/config.json."
  exit 0
fi

SLEEPTIME=90
NODES=12
SLOW_SPEC_THRESHOLD=120

# Build Skip regex to ignore tests
SKIP_REGEX="${SKIP_REGEX:+${SKIP_REGEX}|}routing.API"
SKIP_REGEX="${SKIP_REGEX}|Adding a wildcard route to a domain"
SKIP_REGEX="${SKIP_REGEX}|when app has multiple ports mapped"
SKIP_REGEX="${SKIP_REGEX}|Dynamic ASGs"
SKIP_REGEX="${SKIP_REGEX// /\\s}" # Replace ' ' with \s

export CONFIG
CONFIG="$(pwd)/test-config/config.json"

echo "Sleeping for ${SLEEPTIME} seconds..."
for i in $(seq $SLEEPTIME 1); do echo -ne "$i"'\r'; sleep 1; done; echo

GOPATH="${GOPATH}:$(pwd)"
export GOPATH

echo "Starting acceptace tests"
cd src/github.com/cloudfoundry/cf-acceptance-tests
./bin/test \
  -keepGoing \
  -timeout=1h \
  -flakeAttempts=3 \
  -randomizeAllSpecs \
  -skipPackage=helpers \
  -skip="${SKIP_REGEX}" \
  -slowSpecThreshold=${SLOW_SPEC_THRESHOLD} \
  -nodes="${NODES}"
