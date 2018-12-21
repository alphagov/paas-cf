#!/usr/bin/env bash

set -e -u -o pipefail

delete=no

for i in "$@"
do
  case $i in
      --help)
        echo "The script will gather users without usernames and will delete them"
        echo "By default users to be deleted will only be printed, use the --delete option to really remove these users"
        exit 1
      ;;
      --delete)
      delete=yes
      ;;
      *)
        echo "Unknown option: $i"
        exit 1
      ;;
  esac
done

next_url="/v2/users?order-direction=desc&results-per-page=100"
all_guids_to_delete=""

while [ "${next_url}" != "null" ]; do
  echo "Processing users from: ${next_url}"
  cf_users=$(cf curl "${next_url}")
  next_url=$(echo "${cf_users}" | jq '.next_url' -r)
  length=$(echo "${cf_users}" | jq '.resources | length')

  echo "Records: ${length}"

  guids_to_delete=$(echo "${cf_users}" | jq '.resources[] | select(.metadata.guid|test("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}")) | select(.entity|has("username") | not) | .metadata.guid' -r)

  guids_not_uuid=$(echo "${cf_users}" | jq '.resources[] | select(.metadata.guid|test("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}")|not) | .metadata.guid' -r)

  usernames_to_keep=$(echo "${cf_users}" | jq '.resources[] | select(.metadata.guid|test("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}")) | select(.entity|has("username")) | .entity.username' -r)

  if [ -n "${guids_not_uuid}" ]; then
    cnt=$(echo "${guids_not_uuid}" | wc -l | tr -d ' ')
    echo "Keeping users with non-uuid guid (${cnt}): "
    echo "${guids_not_uuid}"
  fi

  if [ -n "${usernames_to_keep}" ]; then
    cnt=$(echo "${usernames_to_keep}" | wc -l | tr -d ' ')
    echo "Keeping users with usernames: (${cnt})"
    echo "${usernames_to_keep}"
  fi

  if [ -n "${guids_to_delete}" ]; then
    cnt=$(echo "${guids_to_delete}" | wc -l | tr -d ' ')
    echo "The following guids will be deleted: (${cnt})"
    echo "${guids_to_delete}"

    all_guids_to_delete="${all_guids_to_delete}${guids_to_delete}
"
  fi
done

if [ -z "${all_guids_to_delete}" ]; then
  echo
  echo "Nothing to delete"
  echo
  exit 0
fi

# This seemingly useless line strips the trailing new line from the end
# shellcheck disable=SC2116
all_guids_to_delete=$(echo "${all_guids_to_delete}")

if [ "${delete}" == "yes" ]; then
  cnt=$(echo "${all_guids_to_delete}" | wc -l | tr -d ' ')
  echo
  echo "Deleting ${cnt} users"
  echo

  while read -r guid; do
    echo "Deleting ${guid}"
    cf curl -X DELETE "/v2/users/${guid}"
  done <<< "${all_guids_to_delete}"

  echo
  echo "Finished"
  echo
else
  echo
  echo "No users were deleted, use the --delete option"
  echo
fi
