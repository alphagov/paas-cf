#!/usr/bin/env bash

set -euo pipefail

echo "${0#$PWD}" >> ~/.paas-script-usage

cflinuxfs3_uuid=$(cf stack cflinuxfs3 --guid)
all_orgs_next_url="/v2/organizations?order-by=name"
echo "org,space,appname,stack,"
while [ "${all_orgs_next_url}" != "null" ]
do
    orgs_response=$(cf curl "${all_orgs_next_url}" | jq)
    orgs=$(echo "${orgs_response}" | jq -r '.resources[] | [.metadata.guid, .metadata.url] | @csv')
    while read -r org
    do
        orginfo=$(cf curl "$(echo "${org}" | cut -d',' -f2 | jq -r)")
        org_name=$(echo "${orginfo}" | jq -r '.entity.name')

        next_space_url=$(echo "${orginfo}" | jq -r '.entity.spaces_url')
        while [ "${next_space_url}" != "null" ]
        do
            org_spaces_response=$(cf curl "${next_space_url}")
            org_spaces=$(echo "${org_spaces_response}" | jq -r '.resources[] | [.metadata.guid, .metadata.url] | @csv')
            while read -r space
            do
                space_uuid=$(echo "${space}" | cut -d',' -f1 | jq -r)
                if [ -z "${space_uuid}" ]; then continue; fi
                spaceinfo=$(cf curl "$(echo "${space}" | cut -d',' -f2 | jq -r)")
                space_name=$(echo "${spaceinfo}" | jq -r '.entity.name')

                next_space_app_url=$(echo "${spaceinfo}" | jq -r '.entity.apps_url')
                while [ "${next_space_app_url}" != "null" ]
                do
                    space_apps_response=$(cf curl "${next_space_app_url}")
                    space_apps=$(echo "${space_apps_response}" | jq -r '.resources[] | [.metadata.guid, .entity.name, .entity.stack_guid, .entity.docker_image] | @csv')
                    while read -r app
                    do
                        app_uuid=$(echo "${app}" | cut -d',' -f1 | jq -r)
                        if [ -z "${app_uuid}" ]; then continue; fi
                        app_name=$(echo "${app}" | cut -d',' -f2 | jq -r)
                        app_stack_guid=$(echo "${app}" | cut -d',' -f3 | jq -r)
                        app_docker_image=$(echo "${app}" | cut -d',' -f4 | jq -r)
                        if [ -n "${app_docker_image}" ]
                        then
                            stack="docker"
                        elif [ "${app_stack_guid}" == "${cflinuxfs3_uuid}" ]
                        then
                            stack="cflinuxfs3"
                        else
                            stack="unknown"
                        fi
                        echo "'${org_name}','${space_name}','${app_name}','${stack}',"
                    done <<< "${space_apps}"
                    next_space_app_url=$(echo "${space_apps_response}" | jq -r '.next_url')
                done
            done <<< "${org_spaces}"
            next_space_url=$(echo "${org_spaces_response}" | jq -r '.next_url')
        done
    done <<< "${orgs}"
    all_orgs_next_url=$(echo "${orgs_response}" | jq -r '.next_url')
done
