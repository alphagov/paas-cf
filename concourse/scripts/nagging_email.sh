#!/bin/sh

set -eu

DEPLOY_ENV=$1
SYSTEM_DNS_ZONE_NAME=$2
ALERT_EMAIL_ADDRESS=$3
MESSAGE_TYPE=$4
CONTEXT=$5

TO="${ALERT_EMAIL_ADDRESS}"
FROM="${ALERT_EMAIL_ADDRESS}"

write_message_json() {
  if [ "${MESSAGE_TYPE}" = 'resurrector-disabled' ]; then
    cat <<EOF > message.json
{
  "Subject": {
    "Data": "Resurrector is disabled in ${DEPLOY_ENV}"
  },
  "Body": {
    "Html": {
      "Data": "Bosh's resurrector is currently disabled in <b>${DEPLOY_ENV}</b>. Presumably \
      this is deliberate, but you probably want to \
      <a href='https://team-manual.cloud.service.gov.uk/guides/restoring_bosh_director/'>re-enable it as soon as you deem sensible</a>, \
      to avoid having to go and recreate dead instances manually. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/teams/main/pipelines/create-cloudfoundry?group=health'>Concourse</a> \
      for details<br/>Alternatively, something else caused this check to fail, which is also \
      something that should be investigated."
    }
  }
}
EOF
  elif [ "${MESSAGE_TYPE}" = 'az-disabled-manifest' ]; then
    cat <<EOF > message.json
{
  "Subject": {
    "Data": "AZ ${CONTEXT} is disabled in ${DEPLOY_ENV}'s manifest"
  },
  "Body": {
    "Html": {
      "Data": "No instance_groups in <b>${DEPLOY_ENV}</b> are configured to use \
      <b>${CONTEXT}</b>. Presumably the AZ has been disabled and this is deliberate, \
      but you probably want to re-enable it as soon as you deem sensible. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/teams/main/pipelines/create-cloudfoundry?group=health'>Concourse</a> \
      for details<br/>Alternatively, something else caused this check to fail, which is also \
      something that should be investigated."
    }
  }
}
EOF
  elif [ "${MESSAGE_TYPE}" = 'az-disabled-vpc' ]; then
    cat <<EOF > message.json
{
  "Subject": {
    "Data": "AZ ${CONTEXT} is disabled in ${DEPLOY_ENV}'s VPC"
  },
  "Body": {
    "Html": {
      "Data": "<b>${DEPLOY_ENV}</b>'s VPC appears to have a network ACL disabling AZ \
      <b>${CONTEXT}</b>. Presumably this is deliberate, but you probably want to re-enable \
      it as soon as you deem sensible. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/teams/main/pipelines/create-cloudfoundry?group=health'>Concourse</a> \
      for details<br/>Alternatively, something else caused this check to fail, which is also \
      something that should be investigated."
    }
  }
}
EOF
  fi
}

write_message_json

aws ses send-email --region eu-west-1 --to "${TO}" --message file://message.json --from "${FROM}"
