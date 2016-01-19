#!/bin/sh
set -u
set -e
echo "Setting up concourse basic auth as ${CONCOURSE_ATC_USER}: ${CONCOURSE_ATC_PASSWORD}"
sed "s/--development-mode//g" -i /var/vcap/jobs/atc/bin/atc_ctl      # dev mode disables all auth
sed "s/--basic-auth-username.*/--basic-auth-username \'${CONCOURSE_ATC_USER}\' \\\/" -i /var/vcap/jobs/atc/bin/atc_ctl
sed "s/--basic-auth-password.*/--basic-auth-password \'${CONCOURSE_ATC_PASSWORD}\' \\\/" -i /var/vcap/jobs/atc/bin/atc_ctl
/var/vcap/bosh/bin/monit restart atc

