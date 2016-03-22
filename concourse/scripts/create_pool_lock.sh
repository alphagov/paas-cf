#!/bin/sh
set -u
set -e

# Params: GITREPO, SSHKEY, POOLNAME, LOCKNAME
# Call example: ./create_pool_lock.sh git@github.com:govuk/locks.git ./id_rsa example_pool example_lock

git_repo=$1
ssh_key=$2
pool_name=$3
lock_name=$4
local_dir="pool_lock_repo"

if [ ! -s "$ssh_key" ]; then
    echo "ERROR: SSH key '${ssh_key}' not found"
    exit 1
fi

export GIT_SSH_COMMAND="ssh -i '$ssh_key' -F /dev/null -o StrictHostKeyChecking=no"
if [ ! -d "$local_dir" ]; then
    git clone -q --single-branch "$git_repo" "$local_dir"
fi

cd "$local_dir"

# Pull latest changes only if the repo is not empty (HEAD exists)
if git rev-parse HEAD > /dev/null 2>&1; then
    git pull -q
fi

if [ ! -d "${pool_name}" ]; then
    echo "No '${pool_name}' pool found, creating..."
    mkdir -p "${pool_name}"
    for lock_status in claimed unclaimed; do
        mkdir -p "${pool_name}/${lock_status}"
        touch "${pool_name}/${lock_status}/.gitkeep"
    done
fi

if [ ! -f "${pool_name}/claimed/${lock_name}" ] && ! [ -f "${pool_name}/unclaimed/${lock_name}" ]; then
    echo "No '${lock_name}' lock found in pool '${pool_name}', creating..."
    touch "${pool_name}/unclaimed/${lock_name}"
    git add .
    git commit -q -m "Add unclaimed '${lock_name}' lock."
    git push -q
fi
