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

# FIXME: Remove this once we've upgraded to CF 257+
if [ "$(git rev-parse HEAD)" != "fd86457abc905ead9e4215a24eee0dc8d2189c12" ]; then
  echo "Unexpected revision of smoke tests repo. Check FIXME in ${BASH_SOURCE[0]}"
  exit 1
fi
# Checkout SHA of merge of https://github.com/cloudfoundry/cf-smoke-tests/pull/28
# This is the only change from the existing commit.
git checkout 20b5a25d

echo "Starting smoke tests"
./bin/test -keepGoing
