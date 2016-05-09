#!/bin/sh

set -e
set -u

TESTS_DIR="${1}"

cd "${TESTS_DIR}"
export GOPATH
GOPATH="${GOPATH}:$(pwd)"
godep restore
go test
