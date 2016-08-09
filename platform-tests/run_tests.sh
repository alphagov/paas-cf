#!/bin/sh

set -e
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
GOPATH="${GOPATH}:${SCRIPT_DIR}"
export GOPATH

TESTS_DIR="${1}"
cd "${TESTS_DIR}"

if [ -x ./run_tests.sh ]; then
  ./run_tests.sh
else
  go test
fi
