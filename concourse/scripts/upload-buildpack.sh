#!/bin/bash
set -eu -o pipefail

if [ "$#" -lt 5 ]; then
    cat <<EOF
Check and setup the given buildpack

Example:

$0 \\
   staticfile_buildpack cflinuxfs3 \\
   staticfile-buildpack-cflinuxfs3-v1.4.33.zip \\
   https://github.com/cloudfoundry/staticfile-buildpack/releases/download/v1.4.33/staticfile-buildpack-cflinuxfs3-v1.4.33.zip \\
   ff367a29f0eb25d26038784773dd28cac52069176b28e43b45795a178d5ea94c
EOF
fi

name="$1"
stack="$2"
filename="$3"
url="$4"
checksum="$5"

existing="$(cf curl '/v3/buildpacks?per_page=100' | jq -r --arg name "$name" '.resources | map(select(.name == $name))[0] | [.name, .stack, .filename] | join(" ")')"
if [ "$existing" = "$name $stack $filename" ]; then
    echo "${filename} already set for ${name} ${stack}, skipping"
    exit 0
fi

echo "Downloading ${url}..."

# Download and checksum
curl -LfqsS "${url}" -o "${filename}"

file_checksum="$(sha256sum "${filename}" | cut -f 1 -d ' ')"
if [ "${file_checksum}" != "${checksum}" ]; then
    echo "Error: ${filename} at ${url} checksum differ. Expected ${checksum} got ${file_checksum}"
    exit 1
fi

echo "Setting up ${filename}..."

existing="$(cf curl '/v3/buildpacks?per_page=100' | jq -r --arg name "$name" '.resources | map(select(.name == $name))[0] | [.name, .stack] | join(" ")')"
if [ "$existing" = "$name $stack" ]; then
  cf update-buildpack \
    "${name}" \
    -p "${filename}" \
    -s "${stack}" \
    --enable
else
  tmpname="__tmp_$$"
  cf create-buildpack \
    "${tmpname}" \
    "${filename}" \
    9999

  cf update-buildpack "${tmpname}" \
    --rename "${name}" \
    --assign-stack "${stack}" \
    --enable
fi
