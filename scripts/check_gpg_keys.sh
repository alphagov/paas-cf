#! /usr/bin/env bash

key_servers=( "hkp://keyserver.ubuntu.com" "hkps://keys.openpgp.org")
exit_code="0"

while read -r key; do
    found="0"
    server_found_in=""
    for server in "${key_servers[@]}"; do
        if gpg --keyserver "${server}" --dry-run --quiet --recv "${key}"; then
            found="1"
            server_found_in="$server"
            break
        fi
    done

   if [[ "$found" == "0" ]]; then
        echo "${key}: not found"
        exit_code="1"
   else
        echo "${key}: found in ${server_found_in}"
   fi
done < .gpg-id

exit "$exit_code"