#!/bin/bash
if [ -z "$AWS_SESSION_TOKEN" ]; then
  echo "No temporary AWS credentials found, please run create_sts_token.sh"
  exit 255;
fi

aws iam get-user > /dev/null 2>&1
if [[ $? != 0 ]]; then
  echo "Current AWS credentials are invalid, please refresh them using create_sts_token.sh"
  exit 255;
fi
