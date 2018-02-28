#!/bin/bash

set -eu -o pipefail

main_file="$1"; shift

# shellcheck disable=SC2086
for i in "$@"; do
        bosh_args="${bosh_args:-} --vars-file=$i"
done

# shellcheck disable=SC2086
bosh interpolate --var-errs $bosh_args "$main_file"
