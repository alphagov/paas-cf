#!/bin/sh

set -eu

nodes=16
if [ "${SLIM_DEV_DEPLOYMENT:-}" = "true" ]; then
  nodes=8
fi

if [ -n "${GINKGO_FOCUS:-}" ]; then
  ginkgo -p -nodes="${nodes}" -focus="${GINKGO_FOCUS}"
else
  ginkgo -p -nodes="${nodes}"
fi
