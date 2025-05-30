#!/bin/bash

set -e

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <org1> [<org2> ...]"
  exit 1
fi

cf target > /dev/null 2>&1 || {
  echo "Not logged into Cloud Foundry. Please run 'cf login' first."
  exit 1
}

for org in "$@"; do
  echo ""
  echo "=== Org: $org ==="

  if ! cf target -o "$org" > /dev/null 2>&1; then
    echo "Error: Unable to target org $org"
    continue
  fi

  spaces=$(cf spaces | tail -n +4)

  for space in $spaces; do
    echo ""
    echo "  -> Space: $space"
    cf target -o "$org" -s "$space" > /dev/null 2>&1

    echo "    Buildpack Usage:"
    cf curl /v3/apps | jq -r '.resources[].guid' | while read -r guid; do
      cf curl "/v3/apps/$guid" | jq -r '.lifecycle.data.buildpacks[]? // "default"'
    done | sort | uniq -c | awk '{printf "      %s: %s\n", $2, $1}'

    echo "    Service Types:"
    cf services | tail -n +5 | awk '{print $2}' | sort | uniq -c | awk '{printf "      %s: %s\n", $2, $1}'
  done
done
