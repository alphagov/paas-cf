#!/bin/bash
set -eu

TMPDIR=${TMPDIR:-/tmp}
TF_DATA_DIR=$(mktemp -d "${TMPDIR}/terraform_lint.XXXXXX")
trap 'rm -r "${TF_DATA_DIR}"' EXIT

export TF_DATA_DIR

for dir in terraform/*/; do
  terraform -chdir="${dir}" init -backend=false >/dev/null
  terraform -chdir="${dir}"  validate >/dev/null
  terraform -chdir="${dir}" fmt -write=false -diff -recursive >> "${TF_DATA_DIR}"/lint
done

if [ -s "${TF_DATA_DIR}"/lint ]; then
  cat "${TF_DATA_DIR}"/lint
  echo ""
  echo "========================================================="
  echo ""
  echo "attempt to automatically fix with make terraform-fix"
  echo ""
  exit 1
else
  echo ""
  echo "========================================================="
  echo ""
  echo "No errors have been found"
  echo ""
  exit 0
fi

