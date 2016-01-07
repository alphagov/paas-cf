#!/bin/sh
bucket=$1
file=$2

# Attempt to use instance profile if keys not configured
if [ -z "${AWS_SECRET_ACCESS_KEY}" ] && [ -z "${AWS_ACCESS_KEY_ID}" ] ; then
  meta_url="http://169.254.169.254/latest/meta-data/iam/security-credentials/"
  profile_name=$(curl -s ${meta_url})
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
region=eu-west-1
host=${bucket}.s3-${region}.amazonaws.com

sign() {
  string=$1
  /bin/echo -e -n "${string}" | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64
}

date=$(date +"%a, %d %b %Y %T %z")
string="GET\n\n${content_type}\n${date}\n${AWS_SECURITY_TOKEN:+x-amz-security-token:$AWS_SECURITY_TOKEN\n}/${bucket}${aws_path}${file}"
signature=$(sign "${string}")
curl -o "${file}" -s -f \
  --write-out "Response code: %{http_code}\nBytes: %{size_download}\n" \
  -H "Host: ${bucket}.s3.amazonaws.com" \
  -H "Date: ${date}" \
  -H "Content-Type: ${content_type}" \
  ${AWS_SECURITY_TOKEN:+-H "x-amz-security-token: ${AWS_SECURITY_TOKEN}"} \
  -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${signature}" \
  "https://${host}/${file}"
