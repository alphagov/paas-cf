#!/bin/bash

set -eu
RELEASE=v1.1.1
PINGDOM_TF_VERSION=v1.1.1
BINARY=terraform-provider-pingdom_${PINGDOM_TF_VERSION}_$(go env GOOS)_$(go env GOARCH)

# Setup the working grounds.
PAAS_CF_DIR=$(pwd)
WORKING_DIR="$(pwd)/$(mktemp -d terraform-lint.XXXXXX)"
echo "Working dir: ${WORKING_DIR}"
trap 'rm -r "${WORKING_DIR}"' EXIT


# Plugins that don't come from the Terraform
# registry must be installed in the users home
# directory in order to be picked up correctly.
PLUGIN_DIR="${HOME}/.terraform.d/plugins/"
mkdir -p "${PLUGIN_DIR}"


# The author of the provider doesn't release it
# compiled for Darwin (Mac) in both x86 and amd64.
# To get around this, we check it out and build
# it ourselves.
if [ "$(uname -s)" = "Darwin" ]; then
  git clone --depth 1 \
    --branch "${RELEASE}" \
    "git@github.com:russellcardullo/terraform-provider-pingdom.git" \
    "${WORKING_DIR}/pingdom-provider"

  cd "${WORKING_DIR}/pingdom-provider"
  go build

  cp "${WORKING_DIR}/pingdom-provider/terraform-provider-pingdom" \
     "${PLUGIN_DIR}/terraform-provider-pingdom_${RELEASE}"

  chmod +x "${PLUGIN_DIR}/terraform-provider-pingdom_${RELEASE}"

  rm -rf "${WORKING_DIR}/pingdom-provider"
else
  wget "https://github.com/russellcardullo/terraform-provider-pingdom/releases/download/${RELEASE}/${BINARY}" \
    -O "${PLUGIN_DIR}/terraform-provider-pingdom_${RELEASE}"
  chmod +x "${PLUGIN_DIR}/terraform-provider-pingdom_${RELEASE}"
fi

cd "${WORKING_DIR}"

for dir in "${PAAS_CF_DIR}"/terraform/*/ ; do
  [[ ${dir} == *"terraform/providers"* ]] && continue
  [[ ${dir} == *"terraform/scripts"* ]] && continue
  [[ ${dir} == *"terraform/spec"* ]] && continue

  terraform init -backend=false "${dir}" >/dev/null
  terraform validate "${dir}"
done

terraform fmt -check -diff "${PAAS_CF_DIR}/terraform"
