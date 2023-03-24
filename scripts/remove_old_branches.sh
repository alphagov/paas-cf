#!/usr/bin/env bash

set -euo pipefail

CUTOFF_DATE="${1}"
if [ -z "${CUTOFF_DATE}" ]; then
    echo "!!! No cutoff date provided"
    echo "!!! Usage: $0 <cutoff_date> [ie. 2021-01-01]"
    exit 1
fi

DEFAULT_BRANCH=${DEFAULT_BRANCH:-$(gh api -X GET "repos/{owner}/{repo}" -q'.default_branch')}

git checkout "${DEFAULT_BRANCH}"
git fetch --all --prune

# Remove local branches that are fully merged
echo "!!! Removing local branches that are fully merged"
git branch --merged | grep -v "${DEFAULT_BRANCH}" | xargs git branch -d || true

# Get all remote branches that are fully merged
readarray -t merged_branches < <(git branch -r --merged "${DEFAULT_BRANCH}" | sed 's/ *origin\///' | grep -v "${DEFAULT_BRANCH}$")

# If there are any branches to remove, ask for confirmation
# and then remove them from the remote
if [ "${#merged_branches[@]}" -ne 0 ]; then
    echo "!!! The following (${#merged_branches[@]}) remote branches are fully merged and will be removed:"
    printf '  - %s\n' "${merged_branches[@]}"
    echo && read -p "Remove these branches? (y/N) " -n 1 -r; echo

    if [ "$REPLY" == "y" ]; then
        for branch in "${merged_branches[@]}"; do
            git push origin --delete "${branch}"
        done

        echo && echo "!!! Done!"
    fi
else
    echo "!!! No remote branches are fully merged and not deleted."
fi

readarray -t all_remote_branches < <(git branch -r | sed 's/ *origin\///' | grep -v "${DEFAULT_BRANCH}$")

declare -A old_remote_branches=()

for branch in "${all_remote_branches[@]}"; do
    if [[ "$(git log "origin/${branch}" --since "${CUTOFF_DATE}" | wc -l)" -eq 0 ]]; then
        last_commit_date=$(git log "origin/${branch}" -1 --format="%cd" --date=short)
        old_remote_branches+=(["${branch}"]="${last_commit_date}")
    fi
done

if [ "${#old_remote_branches[@]}" -ne 0 ]; then
    echo "!!! The following (${#old_remote_branches[@]}) remote branches are older than ${CUTOFF_DATE} and will be removed:"

    for branch in "${!old_remote_branches[@]}"; do
        printf '%s;%s\n' "${old_remote_branches[${branch}]}" "${branch}"
    done | sort -r -t ';' -k 1 | awk -F ';' '{print "  - "$2" ("$1")"}'

    echo && read -p "Remove these branches? (y/N) " -n 1 -r; echo

    if [ "$REPLY" == "y" ]; then
        for branch in "${!old_remote_branches[@]}"; do
            git push origin --delete "${branch}"
        done

        echo && echo "!!! Done!"
    fi
else
    echo "!!! No remote branches are older than ${CUTOFF_DATE}."
fi
