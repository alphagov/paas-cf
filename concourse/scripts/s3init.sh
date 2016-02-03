#!/bin/sh
bucket=$1
file=$2
init_file=$3
set -e

# Attempt to use instance profile if keys not configured
if [ -z "${AWS_SECRET_ACCESS_KEY}" ] && [ -z "${AWS_ACCESS_KEY_ID}" ] ; then
  meta_url="http://169.254.169.254/latest/meta-data/iam/security-credentials/"
  profile_name=$(curl -s "${meta_url}")
  instance_profile=$(curl -s "${meta_url}/${profile_name}")

      AWS_ACCESS_KEY_ID=$(echo "${instance_profile}" | awk -F\" '$2 == "AccessKeyId"     { print $4 }')
     AWS_SECURITY_TOKEN=$(echo "${instance_profile}" | awk -F\" '$2 == "Token"           { print $4 }')
  AWS_SECRET_ACCESS_KEY=$(echo "${instance_profile}" | awk -F\" '$2 == "SecretAccessKey" { print $4 }')

  [ -z "${AWS_SECURITY_TOKEN}" ] && echo "Could not obtain AWS_SECURITY_TOKEN from instance profile" && exit 105
fi

[ -z "${bucket}" ]    && echo "Must provide bucket name"    && exit 100
[ -z "${file}" ]      && echo "Must provide file name"      && exit 101
[ -z "${AWS_ACCESS_KEY_ID}"     ] && echo "AWS_ACCESS_KEY_ID nor specified or present in instance profile"     && exit 103
[ -z "${AWS_SECRET_ACCESS_KEY}" ] && echo "AWS_SECRET_ACCESS_KEY nor specified or present in instance profile" && exit 104

aws_path=/
content_type='application/x-compressed-tar'
acl="x-amz-acl:private"
region=eu-west-1
host=${bucket}.s3-${region}.amazonaws.com

sign() {
  string=$1
  # shellcheck disable=SC2059
  printf "${string}" | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64
}

put() {
  date=$(date +"%a, %d %b %Y %T %z")
  string="PUT\n\n${content_type}\n${date}\n${acl}\n${AWS_SECURITY_TOKEN:+x-amz-security-token:$AWS_SECURITY_TOKEN\n}/${bucket}${aws_path}${file}"
  signature=$(sign "${string}")
  # shellcheck disable=SC2086
  curl -s -X PUT -T "${init_file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${date}" \
    -H "Content-Type: ${content_type}" \
    -H "${acl}" \
    ${AWS_SECURITY_TOKEN:+-H "x-amz-security-token: ${AWS_SECURITY_TOKEN}"} \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${signature}" \
    --dump-header headers.txt \
    "https://${host}${aws_path}${file}"
}

get() {
  date=$(date +"%a, %d %b %Y %T %z")
  string="GET\n\n${content_type}\n${date}\n${AWS_SECURITY_TOKEN:+x-amz-security-token:$AWS_SECURITY_TOKEN\n}/${bucket}${aws_path}${file}"
  signature=$(sign "${string}")
  # shellcheck disable=SC2086
  curl -s \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${date}" \
    -H "Content-Type: ${content_type}" \
    ${AWS_SECURITY_TOKEN:+-H "x-amz-security-token: ${AWS_SECURITY_TOKEN}"} \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${signature}" \
    -o "${file}" \
    --dump-header headers.txt \
    "https://${host}/${file}"
}

get
if grep -q "200 OK" headers.txt; then
  echo "$file already exists in $bucket bucket."
elif  grep -q "<Code>NoSuchKey</Code>" "${file}"; then
  if [ -z "${init_file}" ]; then
    echo "${file} cannot be found in ${bucket} bucket and no init file provided."
    exit 1
  else
    echo "${file} cannot be found in ${bucket} bucket. Uploading init file ${init_file}."
    put
    get
  fi
else
  echo "Unexpected response: $(cat "${file}" headers.txt)"
  exit 1
fi
