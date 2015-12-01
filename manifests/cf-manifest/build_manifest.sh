#!/bin/sh

set -e
cd $(dirname $0)

spruce merge \
  deployments/*.yml \
  deployments/aws/*.yml
