#!/bin/sh

set -eu

if [ $# -lt 2 ]; then
   echo "Usage: $0 <tag> <path>"
fi

expected_tag="$1"
working_dir="$2"

cd "${working_dir}"
current_tags=$(git tag --points-at HEAD)
if ! echo "${current_tags}" | grep -qe "^${expected_tag}\$"; then
   echo "Current tags '$(echo "${current_tags}" | xargs)' != expected tag '${expected_tag}' in cloned repo '${working_dir}'"
   exit 1
fi
