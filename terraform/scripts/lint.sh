#!/bin/bash

set -eu
RELEASE=0.2.2
BINARY=terraform-provider-pingdom-tf-${TF_VERSION}-$(uname -s)-$(uname -m)

# Setup the working grounds.
PAAS_CF_DIR=$(pwd)
WORKING_DIR=$(mktemp -d terraform-lint.XXXXXX)
trap 'rm -r "${PAAS_CF_DIR}/${WORKING_DIR}"' EXIT

wget "https://github.com/alphagov/paas-terraform-provider-pingdom/releases/download/${RELEASE}/${BINARY}" \
  -O "${WORKING_DIR}"/terraform-provider-pingdom
chmod +x "${WORKING_DIR}"/terraform-provider-pingdom

cd "${WORKING_DIR}"

for dir in ${PAAS_CF_DIR}/terraform/*/ ; do
  if [[ ${dir} == *"terraform/providers"* ]] || [[ ${dir} == *"terraform/scripts"* ]]; then
    continue
  fi

  terraform get "${dir}" > /dev/null
  terraform graph "${dir}" > /dev/null
done

if [ "$(terraform fmt -write=false "${PAAS_CF_DIR}/terraform")" != "" ] ; then
  echo "Use 'terraform fmt' to fix HCL formatting:"
  terraform fmt -write=false -diff=true "${PAAS_CF_DIR}/terraform"
  exit 1
fi
