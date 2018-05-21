#!/bin/bash

set -euo pipefail

echo "filter {"
sed 's/^/  /' < config/logit/10_base.conf
sed 's/^/  /' < config/logit/20_logsearch_for_cloudfoundry.conf
sed 's/^/  /' < config/logit/30_custom_filters.conf
echo "}"
