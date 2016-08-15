#!/bin/bash

set -eu
set -o pipefail

TAG_PREFIX="${1}"
AWS_ACCOUNT="${2}"
DEPLOY_ENV="${3}"
TAG_FILTER="${4:-""}"

GIT_EMAIL="the-multi-cloud-paas-team+deployer-ci@digital.cabinet-office.gov.uk"
GIT_USER="gov-paas-${AWS_ACCOUNT}"
GIT_REPO_URL="${GIT_REPO_URL:-git@github.com:alphagov/paas-cf.git}"

echo Configure SSH
tar xzf git-keys/git-keys.tar.gz
mkdir -p ~/.ssh

cat <<EOF > ~/.ssh/config
Host github.com
  StrictHostKeyChecking no
  IdentityFile $(pwd)/git-key
EOF

check_already_tagged() {
  tag_prefix="${1}"
  previous_tags="$(git tag -l --points-at HEAD "${tag_prefix}*")"
  if [ -n "${previous_tags}" ] ; then
    echo "WARNING: already tagged to current commit for environment ${DEPLOY_ENV}. Skipping."
    echo "Tags: ${previous_tags}"
    exit 0
  fi
}

get_tag(){
  tag_filter="${1}"
  git tag -l --points-at HEAD --sort=version:refname "${tag_filter}" | tail -n 1
}

promote_existing_tag(){
  existing_tag=${1}
  # Replace the prefix ${TAG_FILTER}, but without the final *
  # with the new prefix ${TAG_PREFIX}
  echo "${existing_tag/${TAG_FILTER%?}/${TAG_PREFIX}}"
}

create_new_tag(){
  version=$(cat ../release-version/number)
  echo "${TAG_PREFIX}${version}"
}

cd paas-cf
git fetch --tags
check_already_tagged "${TAG_PREFIX}"

echo Configure Git
git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_USER}"
git remote add tag_origin "${GIT_REPO_URL}"

if [ -n "${TAG_FILTER}" ]
then
  latest_tag=$(get_tag "${TAG_FILTER}")
  tag=$(promote_existing_tag "${latest_tag}")
  echo "Promote ${latest_tag} to ${tag}"
else
  tag=$(create_new_tag)
  echo "Create new tag ${tag}"
fi

git tag -a "${tag}" -m "Tag ${tag} passed ${AWS_ACCOUNT} \
in environment ${DEPLOY_ENV}"

echo "Push tag ${tag}"
git push tag_origin "${tag}"
