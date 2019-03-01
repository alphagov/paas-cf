#!/bin/sh

set -eu

DEPLOY_ENV=$1
SYSTEM_DNS_ZONE_NAME=$2
ALERT_EMAIL_ADDRESS=$3

set +u
if [ "$4" = "" ]; then
  message_file=message-local.json
  MONITORED_DEPLOY_ENV=""
else
  message_file=message-remote.json
  MONITORED_DEPLOY_ENV=$4
fi
set -u

TO="${ALERT_EMAIL_ADDRESS}"
FROM="${ALERT_EMAIL_ADDRESS}"
# SMOKE_TEST_LOG=./smoke-tests-log/smoke-tests.log
# LAST_COMMIT_LOG=./smoke-tests-log/last-commit.log

write_message_json() {
  cat <<EOF > message-local.json
{
  "Subject": {
    "Data": "Smoke tests failed in ${DEPLOY_ENV}"
  },
  "Body": {
    "Html": {
      "Data": "The smoke tests have failed in environment <b>${DEPLOY_ENV}</b>. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/teams/main/pipelines/create-cloudfoundry?groups=health'>Concourse</a> \
      for details<br/>"
    }
  }
}
EOF
  cat <<EOF > message-remote.json
{
  "Subject": {
    "Data": "Smoke tests failed in ${MONITORED_DEPLOY_ENV}, says ${DEPLOY_ENV}"
  },
  "Body": {
    "Html": {
      "Data": "The smoke tests monitoring <b>${MONITORED_DEPLOY_ENV}</b> have failed in ${DEPLOY_ENV}'s Concourse. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/teams/main/pipelines/monitor-${MONITORED_DEPLOY_ENV}'>Concourse</a> \
      for details<br/>"
    }
  }
}
EOF
}

write_message_json

aws ses send-email --region eu-west-1 --to "${TO}" --message file://${message_file} --from "${FROM}"
