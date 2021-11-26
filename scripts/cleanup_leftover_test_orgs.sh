#!/usr/bin/env bash

set -e -u -o pipefail

# shellcheck disable=SC2089
ORGS='{"orgs":[]}'
NEXT_PAGE_NUM=1
while true; do
  ORG_RESPONSE=$(cf curl "/v3/organizations?per_page=5000&page=${NEXT_PAGE_NUM}")
  ORGS=$(
    echo "$ORGS" | \
      jq -rc --argjson new "$(echo "${ORG_RESPONSE}" | jq -rc '.resources')" \
        '{"orgs": (.orgs + $new)}'
  )

  NEXT_PAGE_URL="$(echo "${ORG_RESPONSE}" | jq -rc '.pagination.next')"
  if [ "$NEXT_PAGE_URL" == "null" ]; then
    break
  fi

  NEXT_PAGE_NUM=$((NEXT_PAGE_NUM + 1))
done

for ORG in $(echo "${ORGS}" | jq -rc '.orgs[]'); do
  ORG_NAME=$(echo "${ORG}" | jq -rc '.name')

  if [[ "${ORG_NAME}" =~ ^ACC-|AIVENBACC-|ASATS-|BACC-|CATS-|SMOKE-.*$ ]]; then
    echo ""
    echo "---"
    echo "${ORG_NAME} created at $(echo "${ORG}" | jq -rc '.created_at'). Delete? "

    # shellcheck disable=SC2034
    select yn in "Yes" "No";
    do
      case $REPLY in
        1 )
          cf delete-org -f "${ORG_NAME}"
          break
          ;;
        2 ) echo "Not deleting ${ORG_NAME}"; break ;;
        * ) echo "Invalid option. Select 1 or 2" ;;
      esac
    done
  else
    echo "Skipping ${ORG_NAME} because it's not a test org"
  fi
done

echo "All done!"
