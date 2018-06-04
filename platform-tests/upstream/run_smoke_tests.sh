#!/bin/bash

set -eu

export CONFIG
CONFIG="$(pwd)/test-config/config.json"

echo "Linking smoke-tests directory inside $GOPATH"
CF_GOPATH=/go/src/github.com/cloudfoundry
mkdir -p $CF_GOPATH
ln -s "$(pwd)/cf-smoke-tests-release/src/smoke_tests" "${CF_GOPATH}/cf-smoke-tests"

echo "Linking test artifacts directory"
ln -s "$(pwd)/artifacts" /tmp/artifacts

cd "${CF_GOPATH}/cf-smoke-tests"

echo "Starting smoke tests"
./bin/test -keepGoing
