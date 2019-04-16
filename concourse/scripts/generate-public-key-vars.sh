#!/usr/bin/env bash

set -euo pipefail

tmpfile="$(mktemp)"
outfile=./concourse/vars-files/gpg-keys.yml

function finish {
  rm -f "$tmpfile"
}
trap finish EXIT

cat >>"$tmpfile" <<COMMENT
# THIS FILE WAS GENERATED AUTOMATICALLY. DO NOT EDIT
# See https://team-manual.cloud.service.gov.uk/team/working_practices/#merging-pull-requests
COMMENT

cat >>"$tmpfile" <<YAMLPREFIX
---
gpg_public_keys:
YAMLPREFIX

for username in $(cat ./.gpg-id.github-users); do
  echo "Fetching $username's public key(s) ..." >&2
  curl --silent --fail https://github.com/$username.gpg \
  | awk ' BEGIN { print "- |" } { print "  " $0 } '
done >>"$tmpfile"

cat "$tmpfile" >"$outfile" # Not a UUOC; it preserves the perms+owner
