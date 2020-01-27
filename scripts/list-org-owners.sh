#!/bin/bash
set -euo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

if ! cf orgs >/dev/null 2>&1; then
  abort "You need to be logged into CF CLI"
fi

pages=$(cf curl /v3/organizations | jq '.pagination.total_pages')

results=""
for page in $(seq 1 "$pages"); do
  results="$results
$(cf curl "/v3/organizations?page=$page" | jq -r '.resources[] | [.metadata.annotations.owner // "Unknown", .name] | @tsv')"
done

sort <<< "$results" | column -t -s '	'
