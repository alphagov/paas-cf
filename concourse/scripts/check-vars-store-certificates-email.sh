#!/bin/sh

set -eu

DEPLOY_ENV=$1
SYSTEM_DNS_ZONE_NAME=$2
ALERT_EMAIL_ADDRESS=$3

TO="${ALERT_EMAIL_ADDRESS}"
FROM="${ALERT_EMAIL_ADDRESS}"
# SMOKE_TEST_LOG=./smoke-tests-log/smoke-tests.log
# LAST_COMMIT_LOG=./smoke-tests-log/last-commit.log

write_message_json() {

  cat <<EOF > message.json
{
  "Subject": {
    "Data": "Certificates not valid or about to expire in ${DEPLOY_ENV}"
  },
  "Body": {
    "Html": {
      "Data": "There are certificates <b>${DEPLOY_ENV}</b> that are not valid or about to expire. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/teams/main/pipelines/create-cloudfoundry?groups=health'>Concourse</a> \
      for details<br/>"
    }
  }
}
EOF
}

write_message_json

aws ses send-email --region eu-west-1 --to "${TO}" --message file://message.json --from "${FROM}"
