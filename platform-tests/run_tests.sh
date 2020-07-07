#!/bin/sh

set -e
set -u

TESTS_DIR="${1}"
cd "${TESTS_DIR}"

if [ -x ./run_tests.sh ]; then
  ./run_tests.sh
else
  go test
fi
