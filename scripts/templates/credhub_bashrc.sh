#!/usr/bin/env bash
apk add --no-cache util-linux 1>2 2>/dev/null

cat <<EOF
-------
CREDHUB SHELL

From this shell, you can access credhub using the credhub cli.
Basic usage:

  \$ credhub find -p /path/of/secrets
  \$ credhub get -n /name/of/secretc

Some useful credentials path are listed below.

$(column -t -s "|" <<PATHS
PROMETHEUS PASSWORD|/$DEPLOY_ENV/prometheus/prometheus_password
GRAFANA PASSWORD|/$DEPLOY_ENV/prometheus/grafana_password
GRAFANA MONITOR PASSWORD|/$DEPLOY_ENV/prometheus/grafana_mon_password
ALERTMANAGER PASSWORD|/$DEPLOY_ENV/prometheus/alertmanager_password
CF ADMIN PASSWORD|/$DEPLOY_ENV/$DEPLOY_ENV/cf_admin_password
UAA ADMIN CLIENT SECRET|/concourse/main/create-cloudfoundry/uaa_admin_client_secret
PATHS
)
-------
EOF
