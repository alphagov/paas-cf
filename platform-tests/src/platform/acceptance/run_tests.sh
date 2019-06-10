#!/bin/sh

set -eu

nodes=8
if [ "${SLIM_DEV_DEPLOYMENT:-}" = "true" ]; then
  nodes=4
fi

if [ -n "${GINKGO_FOCUS:-}" ]; then
  ginkgo -p \
    -nodes="${nodes}" \
    -progress \
    -timeout=1h30m \
    -focus="${GINKGO_FOCUS}"
else
  ginkgo -p \
    -nodes="${nodes}" \
    -progress \
    -timeout=1h30m
fi
