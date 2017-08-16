#!/bin/bash

set -e
set -u
set -o pipefail

SCRIPT_NAME="$0"
PROJECT_DIR="$(cd "$(dirname "${SCRIPT_NAME}")/.."; pwd)"
TMP_DIR=/tmp/buildpack_release_notes
CF_RELEASE_DIR="${CF_RELEASE_DIR:-${PROJECT_DIR}/cf-release}"

print_help() {
    cat <<EOF
Generates the aggregate summary of changes of all the
buildpacks between two versions of the CF release:

 - $TMP_DIR/summary.md: list of versions and links to the release notes
 - $TMP_DIR/detailed.md: all the changes with the content of the release notes

To use it, you must first clone the cf-release repo:

    git clone http://github.com/cloudfoundry/cf-release.git ../cf-release
    ../cf-release/scripts/update

You can override the path by setting \$CF_RELEASE_DIR


Finally run the program passing the versions to check:

    $0 <version_from> <version_to>

Example:

    $0 v251 v253

or:

    CF_RELEASE_DIR=~/workspace/cf-release/ $0 v251 v253

EOF
    exit 1
}

if [ $# -lt 2 ]; then
    echo -e "Error: Missing versions to compare\n"
    print_help
fi

CF_RELEASE_VERSION_A=$1
CF_RELEASE_VERSION_B=$2

cd "$CF_RELEASE_DIR"
mkdir -p "${TMP_DIR}"

echo -e "# Buildpack updates summary\n" > "${TMP_DIR}"/summary.md
echo -e "# Buildpack updates defailed\n" > "${TMP_DIR}"/detailed.md

for buildpack_release in src/*buildpack-release; do
    echo -e "Buildpack release: ${buildpack_release}"
    case "$buildpack_release" in
        *offline*)
        continue # Ignore offline ones
        ;;
        dotnet-core-buildpack*)
        continue # Ignore dotnet ones
        ;;
        nodejs-buildpack*)
        continue # Upgraded independent of cf-release
        ;;
    esac

    commit_a=$(git diff "${CF_RELEASE_VERSION_A}..${CF_RELEASE_VERSION_B}" "${buildpack_release}" | grep "Subproject commit" | cut -f 3 -d " " | head -n 1)
    commit_b=$(git diff "${CF_RELEASE_VERSION_A}..${CF_RELEASE_VERSION_B}" "${buildpack_release}" | grep "Subproject commit" | cut -f 3 -d " " | tail -n 1)
    if [ -n "${commit_a}" ] && [ -n "${commit_b}" ]; then
        versions=$(
            git --git-dir="${buildpack_release}/.git" \
                --work-tree="${buildpack_release}" \
                diff "${commit_a}".."${commit_b}" 'releases/*/index.yml' | \
                    grep '^+' | grep version: | awk '{ print $3 }' | tr -d \'\" | sort -r
        )

        buildpack_name="$(echo "${buildpack_release}" | sed 's/src\/\(.*\)-release/\1/')"

        (
        echo -e "## ${buildpack_name}\n"
        echo -e "New versions: $(echo "${versions}" | xargs)\n"

        echo -e "Release notes:"
        for v in ${versions}; do
            echo -e " * https://github.com/cloudfoundry/${buildpack_name}/releases/tag/${v}"
        done
        echo
        ) | tee -a "${TMP_DIR}"/summary.md

        for v in ${versions}; do
            echo -e "### ${buildpack_name} ${v}\n"
            curl -qs "https://api.github.com/repos/cloudfoundry/${buildpack_name}/releases/tags/v${v}" | jq -r .body
        done
    fi

done > "${TMP_DIR}"/detailed.md

echo "Files generated. Check ${TMP_DIR}/summary.md and ${TMP_DIR}/detailed.md"

