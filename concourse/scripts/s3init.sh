#!/bin/bash

bucket=$1
file=$2
[[ -z "${bucket}" ]]      && echo "Must provide bucket name"     && exit 100
[[ -z "${file}" ]]      && echo "Must provide file name"     && exit 101

aws_path=/
content_type='application/x-compressed-tar'

sign() {
  string=$1
  echo -en "${string}" | openssl sha1 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64
}

put() {
  date=$(date +"%a, %d %b %Y %T %z")
  acl="x-amz-acl:private"
  string="PUT\n\n$content_type\n$date\n$acl\n/$bucket$aws_path$file"
  signature=$(sign "${string}")
  curl -i -s -X PUT -d "{}" \
    -H "Host: $bucket.s3.amazonaws.com" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:$signature" \
    "https://$bucket.s3.amazonaws.com$aws_path$file"
}

get() {
  date=$(date +"%a, %d %b %Y %T %z")
  string="GET\n\n${contentType}\n${date}\n/$bucket$aws_path$file"
  signature=$(sign "${string}")
  curl -i -s -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${date}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${AWS_ACCESS_KEY_ID}:${signature}" \
    https://${bucket}.s3.amazonaws.com/${file}
}

response=$(get)
if $(echo ${response} | grep -q "200 OK"); then
  echo $file already exists in $bucket bucket.
elif $(echo ${response} | grep -q "<Code>NoSuchKey</Code>"); then
  echo $file cannot be found in $bucket bucket. Creating empty json file.
  put
else
  echo Unexpected response: $response
  exit 1
fi
