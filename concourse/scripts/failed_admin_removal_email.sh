#!/bin/sh
set -eu

DEPLOY_ENV=$1
SYSTEM_DNS_ZONE_NAME=$2
EMAIL=$3

write_message_json() {
  cat <<EOF > message.json
{
  "Subject": {
    "Data": "Temporary admin removal failed in ${DEPLOY_ENV}"
  },
  "Body": {
    "Html": {
      "Data": "Removal of the temporary admin user has failed in continuous smoketests in environment <b>${DEPLOY_ENV}</b>. See \
      <a href='https://deployer.${SYSTEM_DNS_ZONE_NAME}/pipelines/create-bosh-cloudfoundry?groups=health'>Concourse</a> \
      for details<br/>"
    }
  }
}
EOF
}

write_message_json
aws ses send-email --to "${EMAIL}" --message file://message.json --from "${EMAIL}"
