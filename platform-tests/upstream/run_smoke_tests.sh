#!/bin/bash

set -eu

relative_to_absolute_path() {
  echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

set +u
CONFIG="${SMOKE_TEST_CONFIG:-./test-config/config.json}"
set -u

CONFIG="$(relative_to_absolute_path "${CONFIG}")"

[ -f "$CONFIG" ] || {
    echo "Config file \"${CONFIG}\" does not exist"
    exit 1
}

export CONFIG

echo "Linking smoke-tests directory inside $GOPATH"
CF_GOPATH=/go/src/github.com/cloudfoundry
mkdir -p $CF_GOPATH
ln -s "$(pwd)/cf-smoke-tests-release/src/smoke_tests" "${CF_GOPATH}/cf-smoke-tests"

echo "Linking test artifacts directory"
ln -s "$(pwd)/artifacts" /tmp/artifacts

cd "${CF_GOPATH}/cf-smoke-tests"

echo "Starting smoke tests"
./bin/test --keep-going
