#!/usr/bin/env bash
set -euo pipefail

tmpsecrets=$(mktemp /tmp/prom-secrets.XXXXXX)
tmpmanifest=$(mktemp /tmp/prom-manifest.XXXXXX)

cleanup() {
  rm -f "$tmpsecrets" "$tmpmanifest"
}
trap cleanup EXIT

aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/prometheus-vars-store.yml" "$tmpsecrets" 1>&2 >/dev/null
for secret in "$@"; do
  awk \
    -F": " \
    -v secret_name="$secret" \
    '$1 == secret_name {
       print "export", toupper($1) "=" $2
     }' \
  <"$tmpsecrets"
done

# shellcheck disable=SC2015
command -v yq >/dev/null && command -v gron >/dev/null || {
  cat <<END
# Additional Prometheus info requires 'yq' and 'gron':
#   - https://github.com/mikefarah/yq
#   - https://github.com/tomnomnom/gron
END
  exit 0
}

aws s3 cp "s3://gds-paas-${DEPLOY_ENV}-state/prometheus-manifest.yml" "$tmpmanifest" 1>&2 >/dev/null
for json_path in \
  properties.alertmanager.web.external_url \
  properties.prometheus.web.external_url \
  properties.grafana.server.root_url; do

  yq read "$tmpmanifest" --tojson \
  | gron \
  | awk \
    -F" = " \
    -v path="$json_path" \
    '$1 ~ path {
       split(path, name, ".");
       print "export", name[2] "_url=" $2
     }'
done
