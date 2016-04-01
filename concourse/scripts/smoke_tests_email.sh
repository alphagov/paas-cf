#!/bin/sh

set -eu

DEPLOY_ENV=$1
SYSTEM_DNS_ZONE_NAME=$2
ALERT_EMAIL_ADDRESS=$3

TO="${ALERT_EMAIL_ADDRESS}"
FROM="${ALERT_EMAIL_ADDRESS}"
SMOKE_TEST_LOG=./smoke-tests-log/smoke-tests.log
LAST_COMMIT_LOG=./smoke-tests-log/last-commit.log

text_2_html(){
  TEXT_FILE=$1
  sed -e 's@$@<br/>@g' "${TEXT_FILE}" | tr -d '\n' | tr -d '"' | tr -d '\015'
}

write_message_json() {

  cat <<EOF > message.json
{
  "Subject": {
    "Data": "Smoke tests failed in ${DEPLOY_ENV}"
  },
  "Body": {
    "Html": {
      "Data": "The smoke tests have failed in environment <b>${DEPLOY_ENV}</b>. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/pipelines/create-bosh-cloudfoundry?groups=health'>Concourse</a> \
      for details<br/>\
      <h3>Last commit:</h3><br/>$(text_2_html "${LAST_COMMIT_LOG}")<br/>\
      <h3>Smoke test log:</h3><br/>$(text_2_html "${SMOKE_TEST_LOG}")"
    }
  }
}
EOF
}

write_message_json

aws ses send-email --to "${TO}" --message file://message.json --from "${FROM}"
