#!/bin/sh

set -eu

godep restore

if [ -n "${GINKGO_FOCUS:-}" ]; then
  go test -timeout 30m -ginkgo.focus "${GINKGO_FOCUS}"
else
  go test -timeout 30m
fi
