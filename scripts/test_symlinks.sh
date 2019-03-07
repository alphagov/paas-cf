#!/usr/bin/env bash

set -ueo pipefail

R=0
while read -r LINK; do
  if [ ! -r "$LINK" ]; then
    echo "$LINK is a hanging symlink" >&2
    R=1
  fi
done

exit "$R"
