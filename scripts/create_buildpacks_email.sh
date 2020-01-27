#!/usr/bin/env bash
set -e -u -o pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

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
cd "$(dirname "$0")/.."
root_dir="$(pwd)"
ARG=${1:-}

if [ "${ARG}" == "-h" ] || [ "${ARG}" == "--help" ]
then
    echo -e "USAGE:\n   ${0} [old commit sha to diff against / --help / -h]"
    exit 0
elif [[ -n ${ARG} ]]
then
    previous_commit="${ARG}"
else
    previous_commit="$(git log --format=%H --max-count 1 --skip 1 -- "config/buildpacks.yml")"
fi

cd "${root_dir}/tools/buildpacks"

go run email.go structs.go -old <(git show "$previous_commit:config/buildpacks.yml") -new <(git show "head:config/buildpacks.yml")
