#!/bin/bash

set -eu -o pipefail

main_file="$1"; shift

bosh interpolate --var-errs --vars-file=<(spruce merge $@) $main_file
