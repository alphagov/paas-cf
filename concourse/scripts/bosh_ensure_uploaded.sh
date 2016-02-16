#! /bin/sh
set -e -u

script_dir=$(cd "$(dirname "$0")" && pwd)

existing_version=$("${script_dir}/bosh_list_${TYPE}s.rb" | awk -v name="${NAME}" -F"/" '$1 ~ name {print $2}')

if [ "${existing_version}" != "${VERSION}" ]; then
  eval bosh upload "${TYPE}" "${URL}"
else
  echo "${NAME}/${VERSION} is already uploaded"
fi
