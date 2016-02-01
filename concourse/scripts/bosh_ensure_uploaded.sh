#! /bin/sh
set -e -u 

script_dir=$(cd "$(dirname "$0")" && pwd)

bosh -u admin -p "${BOSH_PASSWORD}" target https://10.0.0.6:25555 >/dev/null
bosh login admin "${BOSH_PASSWORD}" >/dev/null

existing_version=$("${script_dir}"/bosh_list_"${TYPE}"s.rb | awk -v name="${NAME}" -F"/" '$1 ~ name {print $2}')

if [[ "${existing_version}" != "${VERSION}" ]]; then
  eval bosh upload "${TYPE}" "${URL}"
else
  echo "${NAME}/${VERSION} is already uploaded"
fi
