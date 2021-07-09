"""
    Usage as a script:

    cf oauth-token | python3 all_syslog_service_instances.py https://my.api.base.url.example.com/
"""

import csv
import sys
from urllib.parse import urljoin

import requests


def get_all_resources_iter(resource_name, api_base_url, headers):
    all_resources = []
    resources_page_resp = requests.get(
        urljoin(api_base_url, resource_name),
        headers=headers,
    )
    resources_page_resp.raise_for_status()
    resources_page = resources_page_resp.json()
    while True:
        yield from resources_page["resources"]

        if not ((resources_page.get("pagination") or {}).get("next") or {}).get("href"):
            break

        resources_page_resp = requests.get(
            resources_page["pagination"]["next"]["href"],
            headers=headers,
        )
        resources_page_resp.raise_for_status()
        resources_page = resources_page_resp.json()

def get_all_v2_resources_iter(resource_name, api_base_url, headers):
    all_resources = []
    resources_page_resp = requests.get(
        urljoin(api_base_url, resource_name),
        headers=headers,
    )
    resources_page_resp.raise_for_status()
    resources_page = resources_page_resp.json()
    while True:
        yield from resources_page["resources"]

        if not resources_page.get("next_url"):
            break

        resources_page_resp = requests.get(
            urljoin(api_base_url, resources_page["next_url"]),
            headers=headers,
        )
        resources_page_resp.raise_for_status()
        resources_page = resources_page_resp.json()

def get_all_resources_dict(resource_name, api_base_url, headers):
    return {s["guid"]: s for s in get_all_resources_iter(resource_name, api_base_url, headers)}


def get_all_v2_resources_dict(resource_name, api_base_url, headers):
    return {s["metadata"]["guid"]: s for s in get_all_v2_resources_iter(resource_name, api_base_url, headers)}


def write_service_instances_csv(f, service_instances, spaces, orgs):
    w = csv.DictWriter(f, ("service_instance_guid","service_instance_name","space_guid","space_name","organization_guid","organization_name", "syslog_drain_url"))
    w.writeheader()
    for service_instance in service_instances.values():
        if service_instance["entity"].get('syslog_drain_url'):
            w.writerow({
                "service_instance_guid": service_instance["metadata"]["guid"],
                "service_instance_name": service_instance["entity"]["name"],
                "space_guid": service_instance["entity"]["space_guid"],
                "space_name": spaces[service_instance["entity"]["space_guid"]]["name"],
                "organization_guid": spaces[service_instance["entity"]["space_guid"]]["relationships"]["organization"]["data"]["guid"],
                "organization_name": orgs[spaces[service_instance["entity"]["space_guid"]]["relationships"]["organization"]["data"]["guid"]]["name"],
                "syslog_drain_url": service_instance["entity"]["syslog_drain_url"]
            })


if __name__ == "__main__":
    auth_header = {
        "Authorization": sys.stdin.read().strip(),
    }
    api_base_url = sys.argv[1]
    service_instances = get_all_v2_resources_dict("/v2/user_provided_service_instances", api_base_url, auth_header)
    spaces = get_all_resources_dict("/v3/spaces", api_base_url, auth_header)
    orgs = get_all_resources_dict("/v3/organizations", api_base_url, auth_header)
    write_service_instances_csv(sys.stdout, service_instances, spaces, orgs)

