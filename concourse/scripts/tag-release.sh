#!/bin/sh

set -eu -o pipefail

TAG_PREFIX="${1}"
AWS_ACCOUNT="${2}"
DEPLOY_ENV="${3}"
TAG_FILTER="${4:-""}"

GIT_EMAIL="the-multi-cloud-paas-team+deployer-ci@digital.cabinet-office.gov.uk"
GIT_USER="gov-paas-${AWS_ACCOUNT}"
GIT_REPO_URL="git@github.com:alphagov/paas-cf.git"

echo Configure SSH
tar xzf git-keys/git-keys.tar.gz
mkdir -p ~/.ssh

cat <<EOF > ~/.ssh/config
Host github.com
  StrictHostKeyChecking no
  IdentityFile $(pwd)/git-key
EOF

get_tag(){
  tag_filter="${1}"
  git tag -l --contains HEAD --sort=version:refname "${tag_filter}" | tail -n 1
}

promote_existing_tag(){
  existing_tag=${1}
  echo "${existing_tag}" | sed s/"${TAG_FILTER%?}"/"${TAG_PREFIX}"/
}

create_new_tag(){
  version=$(cat ../release-version/number)
  echo "${TAG_PREFIX}${version}"
}

cd paas-cf
echo Configure Git
git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_USER}"
git remote add ssh "${GIT_REPO_URL}"

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
git push ssh "${tag}"
