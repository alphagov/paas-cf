#!/usr/bin/env bash
set -e -u -o pipefail

MIN_GO_VERSION=1.11

GORAWVERSION=$(go version)
if [[ ${GORAWVERSION} =~ ([0-9]+\.[0-9]+(\.[0-9])?) ]]
then
    if [ "$(echo -e "${MIN_GO_VERSION}\n${BASH_REMATCH[1]}" | sort -V | head -n 1)" != "${MIN_GO_VERSION}" ]
    then
        echo "at least go ${MIN_GO_VERSION} is required"
        exit 1
    fi
fi

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
temp_file="$(mktemp -t buildpacks.yml)"
trap '{ rm -f ${temp_file}; }' EXIT

cd "$root_dir/tools/buildpacks"
go run main.go structs.go < "$root_dir/config/buildpacks.yml" > "$temp_file"

cp "$temp_file" "$root_dir/config/buildpacks.yml"
