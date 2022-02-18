#!/usr/bin/env bash

set -e -u -o pipefail

ORG_DEL_ERR_FILENAME="./org_deletion_failed.txt"
NEXT_PAGE_NUM=1
while true; do
  ORG_RESPONSE=$(cf curl "/v3/organizations?per_page=200&page=${NEXT_PAGE_NUM}")
  ORGS=$(echo "${ORG_RESPONSE}" | jq -c '.resources[] | [.name,.created_at]')

  # Intentionally not quoting ${ORGS} below as it breaks itemization.
  for ORG in ${ORGS}; do
    ORG_NAME=$(echo "${ORG}" | jq -rc '.[0]')
    ORG_CREATED_AT=$(echo "${ORG}" | jq -rc '.[1]')

    if [[ "${ORG_NAME}" =~ ^ACC-|AIVENBACC-|ASATS-|BACC-|CATS-|SMOKE-.*$ ]]; then
      echo ""
      echo "---"
      echo "${ORG_NAME} created at ${ORG_CREATED_AT}. Delete? "

      # shellcheck disable=SC2034
      select yn in "Yes" "No";
      do
        case $REPLY in
          1 )
            cf delete-org -f "${ORG_NAME}" || true

            if cf org "${ORG_NAME}" > /dev/null
            then
              echo "${ORG_NAME}" >> "${ORG_DEL_ERR_FILENAME}"
            fi

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

  NEXT_PAGE_URL="$(echo "${ORG_RESPONSE}" | jq -rc '.pagination.next')"
  if [ "$NEXT_PAGE_URL" == "null" ]; then
    break
  fi

  NEXT_PAGE_NUM=$((NEXT_PAGE_NUM + 1))
done

if test -e "${ORG_DEL_ERR_FILENAME}"
then
  echo "Deletion failed for orgs listed in ${ORG_DEL_ERR_FILENAME}."
fi

echo "All done!"
