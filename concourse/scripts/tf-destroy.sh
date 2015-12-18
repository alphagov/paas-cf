#!/bin/sh
set -e

[[ -z "${TF_VAR_env}" ]]    && echo "TF_VAR_env not set"    && exit 100
[[ -z "${TF_STATE_PATH}" ]] && echo "TF_STATE_PATH not set" && exit 101
[[ -z "${TF_FILES_PATH}" ]] && echo "TF_FILES_PATH not set" && exit 102

cp "${TF_STATE_PATH}" "${TF_FILES_PATH}"/tf-destroy.tfstate
cd "${TF_FILES_PATH}"
terraform destroy -force -state=tf-destroy.tfstate

