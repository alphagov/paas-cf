#!/bin/sh

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

export GOPATH="${GOPATH}:${SCRIPT_DIR}"

cd "${SCRIPT_DIR}/src/acceptance"
godep restore
go test
