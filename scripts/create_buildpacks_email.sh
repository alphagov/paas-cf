#!/usr/bin/env bash
set -e -u -o pipefail

cd "$(dirname "$0")/.."
root_dir="$(pwd)"

if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
    echo -e "USAGE:\n   ${0} [old commit sha to diff against / --help / -h]"
    exit 0
elif [ "${1}" != "" ]; then
    previous_commit="${1}"
else
    previous_commit="$(git log --format=%H --max-count 1 --skip 1 -- "config/buildpacks.yml")"
fi

cd "tools/buildpacks"

go run email.go structs.go -old <(git show "$previous_commit:config/buildpacks.yml") -new <(git show "head:config/buildpacks.yml") -markdownout "${root_dir}/doc/buildpack_release.md"

echo -e "END\n\nMarkdown file created at '${root_dir}/doc/buildpack_release.md'. If happy, stage and commit."
