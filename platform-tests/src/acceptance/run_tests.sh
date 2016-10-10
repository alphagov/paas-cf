#!/bin/sh

set -eu

godep restore

if [ -n "${GINKGO_FOCUS:-}" ]; then
  ginkgo -p -nodes=16 -focus="${GINKGO_FOCUS}"
else
  ginkgo -p -nodes=16
fi
