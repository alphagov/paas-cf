#!/bin/sh

set -eu

nodes=5

if [ -n "${GINKGO_FOCUS:-}" ]; then
  ginkgo -p \
    -nodes="${nodes}" \
    -timeout=40m \
    -focus="${GINKGO_FOCUS}"
else
  ginkgo -p \
    -nodes="${nodes}" \
    -timeout=40m
fi
