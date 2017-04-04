#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/common.sh"

abort "This script is deprecated. Please use: create-user.sh -r"
