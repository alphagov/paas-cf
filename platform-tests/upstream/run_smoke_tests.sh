#!/bin/bash

set -eu

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
