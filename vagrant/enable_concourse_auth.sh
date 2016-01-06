#!/bin/bash

echo "Setting up concourse basic auth as $1 : $2"
sed "s/--development-mode//g" -i /var/vcap/jobs/atc/bin/atc_ctl      # dev mode disables all auth
sed "s/--basic-auth-username.*/--basic-auth-username \'$1\' \\\/" -i /var/vcap/jobs/atc/bin/atc_ctl
sed "s/--basic-auth-password.*/--basic-auth-password \'$2\' \\\/" -i /var/vcap/jobs/atc/bin/atc_ctl

/var/vcap/bosh/bin/monit restart atc
