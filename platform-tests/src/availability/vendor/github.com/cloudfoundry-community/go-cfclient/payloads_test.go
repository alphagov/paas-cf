package cfclient

const listOrgsPayload = `{
"total_results": 6,
"total_pages": 1,
"prev_url": null,
"next_url": "/v2/orgsPage2",
"resources": [
  {
     "metadata": {
        "guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
        "url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b",
        "created_at": "2014-09-24T13:54:53+00:00",
        "updated_at": null
     },
     "entity": {
        "name": "demo",
        "billing_enabled": false,
        "quota_definition_guid": "183599e0-d535-4559-8675-7b6ddb5cc42d",
        "status": "active",
        "quota_definition_url": "/v2/quota_definitions/183599e0-d535-4559-8675-7b6ddb5cc42d",
        "spaces_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/spaces",
        "domains_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/domains",
        "private_domains_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/private_domains",
        "users_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/users",
        "managers_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/managers",
        "billing_managers_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/billing_managers",
        "auditors_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/auditors",
        "app_events_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/app_events",
        "space_quota_definitions_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/space_quota_definitions"
     }
  },
  {
     "metadata": {
        "guid": "da0dba14-6064-4f7a-b15a-ff9e677e49b2",
        "url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2",
        "created_at": "2014-09-26T13:36:41+00:00",
        "updated_at": null
     },
     "entity": {
        "name": "test",
        "billing_enabled": false,
        "quota_definition_guid": "183599e0-d535-4559-8675-7b6ddb5cc42d",
        "status": "active",
        "quota_definition_url": "/v2/quota_definitions/183599e0-d535-4559-8675-7b6ddb5cc42d",
        "spaces_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/spaces",
        "domains_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/domains",
        "private_domains_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/private_domains",
        "users_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/users",
        "managers_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/managers",
        "billing_managers_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/billing_managers",
        "auditors_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/auditors",
        "app_events_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/app_events",
        "space_quota_definitions_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/space_quota_definitions"
     }
  }
]
}`

const listOrgsPayloadPage2 = `{
"total_results": 6,
"total_pages": 1,
"prev_url": null,
"next_url": null,
"resources": [
  {
     "metadata": {
        "guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
        "url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b",
        "created_at": "2014-09-24T13:54:53+00:00",
        "updated_at": null
     },
     "entity": {
        "name": "demo",
        "billing_enabled": false,
        "quota_definition_guid": "183599e0-d535-4559-8675-7b6ddb5cc42d",
        "status": "active",
        "quota_definition_url": "/v2/quota_definitions/183599e0-d535-4559-8675-7b6ddb5cc42d",
        "spaces_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/spaces",
        "domains_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/domains",
        "private_domains_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/private_domains",
        "users_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/users",
        "managers_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/managers",
        "billing_managers_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/billing_managers",
        "auditors_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/auditors",
        "app_events_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/app_events",
        "space_quota_definitions_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b/space_quota_definitions"
     }
  },
  {
     "metadata": {
        "guid": "da0dba14-6064-4f7a-b15a-ff9e677e49b2",
        "url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2",
        "created_at": "2014-09-26T13:36:41+00:00",
        "updated_at": null
     },
     "entity": {
        "name": "test",
        "billing_enabled": false,
        "quota_definition_guid": "183599e0-d535-4559-8675-7b6ddb5cc42d",
        "status": "active",
        "quota_definition_url": "/v2/quota_definitions/183599e0-d535-4559-8675-7b6ddb5cc42d",
        "spaces_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/spaces",
        "domains_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/domains",
        "private_domains_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/private_domains",
        "users_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/users",
        "managers_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/managers",
        "billing_managers_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/billing_managers",
        "auditors_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/auditors",
        "app_events_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/app_events",
        "space_quota_definitions_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/space_quota_definitions"
     }
  }
]
}`

const orgByGuidPayload = `{
  "metadata": {
    "guid": "1c0e6074-777f-450e-9abc-c42f39d9b75b",
    "url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b",
    "created_at": "2016-06-08T16:41:33Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1716",
    "billing_enabled": false,
    "quota_definition_guid": "769e777f-92b6-4ba0-9e48-5f77e6293670",
    "status": "active",
    "quota_definition_url": "/v2/quota_definitions/769e777f-92b6-4ba0-9e48-5f77e6293670",
    "spaces_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/spaces",
    "domains_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/domains",
    "private_domains_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/private_domains",
    "users_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/users",
    "managers_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/managers",
    "billing_managers_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/billing_managers",
    "auditors_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/auditors",
    "app_events_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/app_events",
    "space_quota_definitions_url": "/v2/organizations/1c0e6074-777f-450e-9abc-c42f39d9b75b/space_quota_definitions"
  }
}`

const createOrgPayload = `{
  "metadata": {
    "guid": "22b3b0a0-6511-47e5-8f7a-93bbd2ff446e",
    "url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e",
    "created_at": "2016-06-08T16:41:33Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "my-org-name",
    "billing_enabled": false,
    "quota_definition_guid": "b7887f5c-34bb-40c5-9778-577572e4fb2d",
    "status": "active",
    "quota_definition_url": "/v2/quota_definitions/b7887f5c-34bb-40c5-9778-577572e4fb2d",
    "spaces_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/spaces",
    "domains_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/domains",
    "private_domains_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/private_domains",
    "users_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/users",
    "managers_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/managers",
    "billing_managers_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/billing_managers",
    "auditors_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/auditors",
    "app_events_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/app_events",
    "space_quota_definitions_url": "/v2/organizations/22b3b0a0-6511-47e5-8f7a-93bbd2ff446e/space_quota_definitions"
  }
}`

const orgSpacesPayload = `{
   "total_results": 1,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "b8aff561-175d-45e8-b1e7-67e2aedb03b6",
            "url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6",
            "created_at": "2014-11-12T17:56:22+00:00",
            "updated_at": null
         },
         "entity": {
            "name": "test",
            "organization_guid": "0c69f181-2d31-4326-ac33-be2b114a5f99",
            "space_quota_definition_guid": null,
            "organization_url": "/v2/organizations/0c69f181-2d31-4326-ac33-be2b114a5f99",
            "developers_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/developers",
            "managers_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/managers",
            "auditors_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/auditors",
            "apps_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/apps",
            "routes_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/routes",
            "domains_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/domains",
            "service_instances_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/service_instances",
            "app_events_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/app_events",
            "events_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/events",
            "security_groups_url": "/v2/spaces/b8aff561-175d-45e8-b1e7-67e2aedb03b6/security_groups"
         }
      }
   ]
}`

const orgSummaryPayload = `{
   "guid": "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
   "name": "system",
   "status": "active",
   "spaces": [
      {
         "guid": "494d8b64-8181-4183-a6d3-6279db8fec6e",
         "name": "test",
         "service_count": 1,
         "app_count": 2,
         "mem_dev_total": 32,
         "mem_prod_total": 64
      }
   ]
}`

const orgQuotaPayload = `{
   "metadata": {
      "guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
      "url": "/v2/quota_definitions/a537761f-9d93-4b30-af17-3d73dbca181b",
      "created_at": "2017-01-18T16:39:10Z",
      "updated_at": "2017-01-18T16:46:20Z"
   },
   "entity": {
      "name": "test-2",
      "non_basic_services_allowed": false,
      "total_services": 10,
      "total_routes": 20,
      "total_private_domains": 30,
      "memory_limit": 40,
      "trial_db_allowed": true,
      "instance_memory_limit": 50,
      "app_instance_limit": 60,
      "app_task_limit": 70,
      "total_service_keys": 80,
      "total_reserved_route_ports": 90
   }
}`

const associateOrgManagerPayload = `{
  "metadata": {
    "guid": "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "created_at": "2016-06-08T16:41:34Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1735",
    "billing_enabled": false,
    "quota_definition_guid": "84eed1c7-cc2d-4823-a578-081fef03ba7d",
    "status": "active",
    "quota_definition_url": "/v2/quota_definitions/84eed1c7-cc2d-4823-a578-081fef03ba7d",
    "spaces_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/spaces",
    "domains_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/domains",
    "private_domains_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/private_domains",
    "users_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users",
    "managers_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers",
    "billing_managers_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers",
    "auditors_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors",
    "app_events_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/app_events",
    "space_quota_definitions_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/space_quota_definitions"
  }
}`

const associateOrgAuditorPayload = `{
  "metadata": {
    "guid": "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "created_at": "2016-06-08T16:41:34Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1735",
    "billing_enabled": false,
    "quota_definition_guid": "84eed1c7-cc2d-4823-a578-081fef03ba7d",
    "status": "active",
    "quota_definition_url": "/v2/quota_definitions/84eed1c7-cc2d-4823-a578-081fef03ba7d",
    "spaces_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/spaces",
    "domains_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/domains",
    "private_domains_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/private_domains",
    "users_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users",
    "managers_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers",
    "billing_managers_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers",
    "auditors_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors",
    "app_events_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/app_events",
    "space_quota_definitions_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/space_quota_definitions"
  }
}`

const associateOrgUserPayload = `{
  "metadata": {
    "guid": "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "created_at": "2016-06-08T16:41:34Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1735",
    "billing_enabled": false,
    "quota_definition_guid": "84eed1c7-cc2d-4823-a578-081fef03ba7d",
    "status": "active",
    "quota_definition_url": "/v2/quota_definitions/84eed1c7-cc2d-4823-a578-081fef03ba7d",
    "spaces_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/spaces",
    "domains_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/domains",
    "private_domains_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/private_domains",
    "users_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/users",
    "managers_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/managers",
    "billing_managers_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/billing_managers",
    "auditors_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/auditors",
    "app_events_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/app_events",
    "space_quota_definitions_url": "/v2/organizations/bc7b4caf-f4b8-4d85-b126-0729b9351e56/space_quota_definitions"
  }
}`

const listOrgQuotasPayloadPage1 = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/quota_definitions_page_2",
   "resources": [
      {
         "metadata": {
            "guid": "6f9d3100-44ab-49e2-a4f8-9d7d67651ae7",
            "url": "/v2/quota_definitions/6f9d3100-44ab-49e2-a4f8-9d7d67651ae7",
            "created_at": "2017-01-18T16:39:10Z",
            "updated_at": "2017-01-18T16:46:20Z"
         },
         "entity": {
            "name": "test-1",
            "non_basic_services_allowed": true,
            "total_services": -1,
            "total_routes": 100,
            "total_private_domains": -1,
            "memory_limit": 102400,
            "trial_db_allowed": false,
            "instance_memory_limit": -1,
            "app_instance_limit": -1,
            "app_task_limit": -1,
            "total_service_keys": -1,
            "total_reserved_route_ports": -1
         }
      }
   ]
}`

const listOrgQuotasPayloadPage2 = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
            "url": "/v2/quota_definitions/a537761f-9d93-4b30-af17-3d73dbca181b",
            "created_at": "2017-01-18T16:39:10Z",
            "updated_at": "2017-01-18T16:46:20Z"
         },
         "entity": {
            "name": "test-2",
            "non_basic_services_allowed": false,
            "total_services": 10,
            "total_routes": 20,
            "total_private_domains": 30,
            "memory_limit": 40,
            "trial_db_allowed": true,
            "instance_memory_limit": 50,
            "app_instance_limit": 60,
            "app_task_limit": 70,
            "total_service_keys": 80,
            "total_reserved_route_ports": 90
         }
      }
   ]
}`

const emptyResources = `{
   "total_results": 0,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": []
}`

const listSpacesPayload = `{
   "total_results": 8,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/spacesPage2",
   "resources": [
      {
         "metadata": {
            "guid": "8efd7c5c-d83c-4786-b399-b7bd548839e1",
            "url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1",
            "created_at": "2014-09-24T13:54:54+00:00",
            "updated_at": null
         },
         "entity": {
            "name": "dev",
            "organization_guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
            "space_quota_definition_guid": null,
            "organization_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b",
            "developers_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/developers",
            "managers_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/managers",
            "auditors_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/auditors",
            "apps_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/apps",
            "routes_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/routes",
            "domains_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/domains",
            "service_instances_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/service_instances",
            "app_events_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/app_events",
            "events_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/events",
            "security_groups_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/security_groups"
         }
      },
      {
         "metadata": {
            "guid": "657b5923-7de0-486a-9928-b4d78ee24931",
            "url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931",
            "created_at": "2014-09-26T13:37:31+00:00",
            "updated_at": null
         },
         "entity": {
            "name": "demo",
            "organization_guid": "da0dba14-6064-4f7a-b15a-ff9e677e49b2",
            "space_quota_definition_guid": null,
            "organization_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2",
            "developers_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/developers",
            "managers_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/managers",
            "auditors_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/auditors",
            "apps_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/apps",
            "routes_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/routes",
            "domains_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/domains",
            "service_instances_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/service_instances",
            "app_events_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/app_events",
            "events_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/events",
            "security_groups_url": "/v2/spaces/657b5923-7de0-486a-9928-b4d78ee24931/security_groups"
         }
      }
   ]
}`

const listSpacesPayloadPage2 = `{
   "total_results": 8,
   "total_pages": 2,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "9ffd7c5c-d83c-4786-b399-b7bd54883977",
            "url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977",
            "created_at": "2014-09-24T13:54:54+00:00",
            "updated_at": null
         },
         "entity": {
            "name": "test",
            "organization_guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
            "space_quota_definition_guid": null,
            "organization_url": "/v2/organizations/b737761f-9d93-4b30-af17-3d73dbca18aa",
            "developers_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/developers",
            "managers_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/managers",
            "auditors_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/auditors",
            "apps_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/apps",
            "routes_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/routes",
            "domains_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/domains",
            "service_instances_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/service_inst2ances",
            "app_events_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/app_events",
            "events_url": "/v2/spaces/9ffd7c5c-d83c-4786-b399-b7bd54883977/events",
            "security_groups_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/security_groups"
         }
      },
      {
         "metadata": {
            "guid": "329b5923-7de0-486a-9928-b4d78ee24982",
            "url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982",
            "created_at": "2014-09-26T13:37:31+00:00",
            "updated_at": null
         },
         "entity": {
            "name": "prod",
            "organization_guid": "da0dba14-6064-4f7a-b15a-ff9e677e49b2",
            "space_quota_definition_guid": null,
            "organization_url": "/v2/organizations/ad0dba14-6064-4f7a-b15a-ff9e677e492b",
            "developers_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/developers",
            "managers_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/managers",
            "auditors_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/auditors",
            "apps_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/apps",
            "routes_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/routes",
            "domains_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/domains",
            "service_instances_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/service_instances",
            "app_events_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/app_events",
            "events_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/events",
            "security_groups_url": "/v2/spaces/329b5923-7de0-486a-9928-b4d78ee24982/security_groups"
         }
      }
   ]
}`

const spaceByGuidPayload = `{
  "metadata": {
    "guid": "8efd7c5c-d83c-4786-b399-b7bd548839e1",
    "url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1",
    "created_at": "2014-09-24T13:54:54+00:00",
    "updated_at": null
  },
  "entity": {
    "name": "dev",
    "organization_guid": "a537761f-9d93-4b30-af17-3d73dbca181b",
    "space_quota_definition_guid": null,
    "organization_url": "/v2/organizations/a537761f-9d93-4b30-af17-3d73dbca181b",
    "developers_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/developers",
    "managers_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/managers",
    "auditors_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/auditors",
    "apps_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/apps",
    "routes_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/routes",
    "domains_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/domains",
    "service_instances_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/service_instances",
    "app_events_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/app_events",
    "events_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/events",
    "security_groups_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1/security_groups"
  }
}`

const associateSpaceAuditorPayload = `{
  "metadata": {
    "guid": "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "url": "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "created_at": "2016-06-08T16:41:34Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1735",
    "organization_guid": "227161e2-667b-483f-9821-77257a38997f",
    "space_quota_definition_guid": null,
    "allow_ssh": true,
    "organization_url": "/v2/organizations/227161e2-667b-483f-9821-77257a38997f",
    "developers_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/developers",
    "managers_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/managers",
    "auditors_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/auditors",
    "apps_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/apps",
    "routes_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/routes",
    "domains_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/domains",
    "service_instances_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/service_instances",
    "app_events_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/app_events",
    "events_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/events",
    "security_groups_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/security_groups"
   }
}`

const associateSpaceDeveloperPayload = `{
  "metadata": {
    "guid": "bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "url": "/v2/spaces/bc7b4caf-f4b8-4d85-b126-0729b9351e56",
    "created_at": "2016-06-08T16:41:34Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1735",
    "organization_guid": "227161e2-667b-483f-9821-77257a38997f",
    "space_quota_definition_guid": null,
    "allow_ssh": true,
    "organization_url": "/v2/organizations/227161e2-667b-483f-9821-77257a38997f",
    "developers_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/developers",
    "managers_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/managers",
    "auditors_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/auditors",
    "apps_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/apps",
    "routes_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/routes",
    "domains_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/domains",
    "service_instances_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/service_instances",
    "app_events_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/app_events",
    "events_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/events",
    "security_groups_url": "/v2/spaces/20e7a265-f50d-4c14-ac7e-42c52f9d9cd7/security_groups"
   }
}`

const spaceSummaryPayload = `{
   "guid": "494d8b64-8181-4183-a6d3-6279db8fec6e",
   "name": "test",
   "apps": [
      {
         "guid": "b5f0d1bd-a3a9-40a4-af1a-312ad26e5379",
         "urls": [
            "test-app.local.pcfdev.io"
         ],
         "routes": [
            {
               "guid": "0b44af3e-77e0-4821-abd6-18d8c79309e6",
               "host": "test-app",
               "port": null,
               "path": "",
               "domain": {
                  "guid": "0b183484-45cc-4855-94d4-892f80f20c13",
                  "name": "local.pcfdev.io"
               }
            }
         ],
         "service_count": 1,
         "service_names": [
            "test-service"
         ],
         "running_instances": 1,
         "name": "test-app",
         "production": false,
         "space_guid": "494d8b64-8181-4183-a6d3-6279db8fec6e",
         "stack_guid": "67e019a3-322a-407a-96e0-178e95bd0e55",
         "buildpack": "ruby_buildpack",
         "detected_buildpack": "",
         "detected_buildpack_guid": "d5860c89-fb0a-49f4-a8b7-3220ff91c91d",
         "environment_json": {},
         "memory": 256,
         "instances": 1,
         "disk_quota": 512,
         "state": "STARTED",
         "version": "fa47ec0a-adba-4cc5-b0ee-a8570dc49b3d",
         "command": null,
         "console": false,
         "debug": null,
         "staging_task_id": "a21d69a7-0878-4841-ab53-4b515397dc27",
         "package_state": "STAGED",
         "health_check_type": "port",
         "health_check_timeout": null,
         "staging_failed_reason": null,
         "staging_failed_description": null,
         "diego": true,
         "docker_image": null,
         "package_updated_at": "2017-02-05T12:18:04Z",
         "detected_start_command": "rackup -p $PORT",
         "enable_ssh": true,
         "docker_credentials_json": {
            "redacted_message": "[PRIVATE DATA HIDDEN]"
         },
         "ports": null
      }
   ],
   "services": [
      {
         "guid": "3c5c758c-6b76-46f6-89d5-677909bfc975",
         "name": "test-service",
         "bound_app_count": 1,
         "last_operation": {
            "type": "create",
            "state": "succeeded",
            "description": "",
            "updated_at": "2017-02-05T11:56:14Z",
            "created_at": "2017-02-05T11:56:14Z"
         },
         "dashboard_url": null,
         "service_plan": {
            "guid": "25e717d2-59a1-4cd2-a792-04508f816776",
            "name": "test-plan",
            "service": {
               "guid": "84c238f4-3961-4b10-8406-9003374c1f2b",
               "label": "test-service",
               "provider": null,
               "version": null
            }
         }
      }
   ]
}`

const spaceRolesPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "uaa-id-363",
        "url": "/v2/users/uaa-id-363",
        "created_at": "2016-06-08T16:41:40Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "admin": false,
        "active": false,
        "default_space_guid": null,
        "username": "everything@example.com",
        "space_roles": [
          "space_developer",
          "space_manager",
          "space_auditor"
        ],
        "spaces_url": "/v2/users/uaa-id-363/spaces",
        "organizations_url": "/v2/users/uaa-id-363/organizations",
        "managed_organizations_url": "/v2/users/uaa-id-363/managed_organizations",
        "billing_managed_organizations_url": "/v2/users/uaa-id-363/billing_managed_organizations",
        "audited_organizations_url": "/v2/users/uaa-id-363/audited_organizations",
        "managed_spaces_url": "/v2/users/uaa-id-363/managed_spaces",
        "audited_spaces_url": "/v2/users/uaa-id-363/audited_spaces"
      }
    }
  ]
}`

const spaceQuotaPayload = `{
   "metadata": {
      "guid": "9ffd7c5c-d83c-4786-b399-b7bd54883977",
      "url": "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977",
      "created_at": "2017-02-04T18:11:49Z",
      "updated_at": "2017-02-04T18:11:49Z"
   },
   "entity": {
      "name": "test-2",
      "organization_guid": "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
      "non_basic_services_allowed": false,
      "total_services": 10,
      "total_routes": 20,
      "memory_limit": 30,
      "instance_memory_limit": 40,
      "app_instance_limit": 50,
      "app_task_limit": 60,
      "total_service_keys": 70,
      "total_reserved_route_ports": 80,
      "organization_url": "/v2/organizations/06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
      "spaces_url": "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977/spaces"
   }
}`

const listSpaceQuotasPayloadPage1 = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/space_quota_definitions_page_2",
   "resources": [
      {
         "metadata": {
            "guid": "889aa2ed-a883-4cc0-abe5-804b2503f15d",
            "url": "/v2/space_quota_definitions/889aa2ed-a883-4cc0-abe5-804b2503f15d",
            "created_at": "2017-02-04T18:11:49Z",
            "updated_at": "2017-02-04T18:11:49Z"
         },
         "entity": {
            "name": "test-1",
            "organization_guid": "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
            "non_basic_services_allowed": true,
            "total_services": -1,
            "total_routes": 100,
            "memory_limit": 102400,
            "instance_memory_limit": -1,
            "app_instance_limit": -1,
            "app_task_limit": -1,
            "total_service_keys": -1,
            "total_reserved_route_ports": -1,
            "organization_url": "/v2/organizations/06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
            "spaces_url": "/v2/space_quota_definitions/889aa2ed-a883-4cc0-abe5-804b2503f15d/spaces"
         }
      }
   ]
}`

const listSpaceQuotasPayloadPage2 = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "9ffd7c5c-d83c-4786-b399-b7bd54883977",
            "url": "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977",
            "created_at": "2017-02-04T18:11:49Z",
            "updated_at": "2017-02-04T18:11:49Z"
         },
         "entity": {
            "name": "test-2",
            "organization_guid": "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
            "non_basic_services_allowed": false,
            "total_services": 10,
            "total_routes": 20,
            "memory_limit": 30,
            "instance_memory_limit": 40,
            "app_instance_limit": 50,
            "app_task_limit": 60,
            "total_service_keys": 70,
            "total_reserved_route_ports": 80,
            "organization_url": "/v2/organizations/06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
            "spaces_url": "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977/spaces"
         }
      }
   ]
}`

const listSecGroupsPayload = `{
   "total_results": 28,
   "total_pages": 1,
   "prev_url": null,
   "next_url": "/v2/security_groupsPage2",
   "resources": [
      {
         "metadata": {
            "guid": "af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c",
            "url": "/v2/security_groups/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c",
            "created_at": "2015-12-04T11:15:55Z",
            "updated_at": null
         },
         "entity": {
            "name": "secgroup-test",
            "rules": [
               {
                  "destination": "1.1.1.1",
                  "ports": "443,4443",
                  "protocol": "tcp"
               },
               {
                  "destination": "1.2.3.4",
                  "ports": "1111",
                  "protocol": "udp"
               }
            ],
            "running_default": true,
            "staging_default": true,
            "spaces_url": "/v2/security_groups/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/spaces",
            "spaces": []
         }
      }
   ]
}`

const listSecGroupsPayloadPage2 = `{
   "total_results": 28,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "f9ad202b-76dd-44ec-b7c2-fd2417a561e8",
            "url": "/v2/security_groups/f9ad202b-76dd-44ec-b7c2-fd2417a561e8",
            "created_at": "2015-12-04T11:15:55Z",
            "updated_at": null
         },
         "entity": {
            "name": "secgroup-test2",
            "rules": [
               {
                  "destination": "2.2.2.2",
                  "ports": "2222",
                  "protocol": "udp"
               },
               {
                  "destination": "4.3.2.1",
                  "ports": "443,4443",
                  "protocol": "tcp"
               }
            ],
            "running_default": false,
            "staging_default": false,
            "spaces_url": "/v2/security_groups/f9ad202b-76dd-44ec-b7c2-fd2417a561e8/spaces",
            "spaces": [
               {
                  "metadata": {
                     "guid": "e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4",
                     "url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4",
                     "created_at": "2014-10-27T10:49:37Z",
                     "updated_at": "2015-01-21T15:30:52Z"
                  },
                  "entity": {
                     "name": "space-test",
                     "organization_guid": "82338ba1-bc08-4576-aad1-9a5b4693b386",
                     "space_quota_definition_guid": null,
                     "allow_ssh": true,
                     "organization_url": "/v2/organizations/82338ba1-bc08-4576-aad1-9a5b4693b386",
                     "developers_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/developers",
                     "managers_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/managers",
                     "auditors_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/auditors",
                     "apps_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/apps",
                     "routes_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/routes",
                     "domains_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/domains",
                     "service_instances_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/service_instances",
                     "app_events_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/app_events",
                     "events_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/events",
                     "security_groups_url": "/v2/spaces/e0a0d1bf-ad74-4b3c-8f4a-0c33859a54e4/security_groups"
                  }
               },
               {
                  "metadata": {
                     "guid": "a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333",
                     "url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333",
                     "created_at": "2014-10-27T10:49:37Z",
                     "updated_at": "2015-01-21T15:30:52Z"
                  },
                  "entity": {
                     "name": "space-test2",
                     "organization_guid": "82338ba1-bc08-4576-aad1-9a5b4693b386",
                     "space_quota_definition_guid": null,
                     "allow_ssh": true,
                     "organization_url": "/v2/organizations/82338ba1-bc08-4576-aad1-9a5b4693b386",
                     "developers_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/developers",
                     "managers_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/managers",
                     "auditors_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/auditors",
                     "apps_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/apps",
                     "routes_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/routes",
                     "domains_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/domains",
                     "service_instances_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/service_instances",
                     "app_events_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/app_events",
                     "events_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/events",
                     "security_groups_url": "/v2/spaces/a2a0d1bf-ad74-4b3c-8f4a-0c33859a5333/security_groups"
                  }
               },
               {
                  "metadata": {
                     "guid": "c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1",
                     "url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1",
                     "created_at": "2014-10-27T10:49:37Z",
                     "updated_at": "2015-01-21T15:30:52Z"
                  },
                  "entity": {
                     "name": "space-test3",
                     "organization_guid": "82338ba1-bc08-4576-aad1-9a5b4693b386",
                     "space_quota_definition_guid": null,
                     "allow_ssh": true,
                     "organization_url": "/v2/organizations/82338ba1-bc08-4576-aad1-9a5b4693b386",
                     "developers_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/developers",
                     "managers_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/managers",
                     "auditors_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/auditors",
                     "apps_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/apps",
                     "routes_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/routes",
                     "domains_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/domains",
                     "service_instances_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/service_instances",
                     "app_events_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/app_events",
                     "events_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/events",
                     "security_groups_url": "/v2/spaces/c7a0d1bf-ad74-4b3c-8f4a-0c33859adsa1/security_groups"
                  }
               }
            ]
         }
      }
   ]
}`

const listAppsPayload = `{
   "total_results": 28,
   "total_pages": 1,
   "prev_url": null,
   "next_url": "/v2/appsPage2",
   "resources": [
      {
         "metadata": {
            "guid": "af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c",
            "url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c",
            "created_at": "2014-10-10T21:03:13+00:00",
            "updated_at": "2014-11-10T14:07:31+00:00"
         },
         "entity": {
            "name": "app-test",
            "production": false,
            "space_guid": "8efd7c5c-d83c-4786-b399-b7bd548839e1",
            "stack_guid": "2c531037-68a2-4e2c-a9e0-71f9d0abf0d4",
            "buildpack": "https://github.com/cloudfoundry/buildpack-go.git",
            "detected_buildpack": "",
            "detected_buildpack_guid": "0d22f6a1-76c5-417f-ac6c-d9d21463ecbc",
            "environment_json": {
               "FOOBAR": "QUX"
            },
            "memory": 256,
            "instances": 1,
            "disk_quota": 1024,
            "state": "STARTED",
            "version": "97ef1272-9eb6-4839-9df1-5ed4f55b5c45",
            "command": null,
            "console": false,
            "debug": null,
            "staging_task_id": "5879c8d06a10491a879734162000def8",
            "package_state": "PENDING",
            "health_check_http_endpoint": null,
            "health_check_type": "port",
            "health_check_timeout": null,
            "staging_failed_reason": null,
            "staging_failed_description": null,
            "diego": true,
            "docker_image": null,
            "package_updated_at": "2014-11-10T14:08:50+00:00",
            "detected_start_command": "app-launching-service-broker",
            "enable_ssh": true,
            "docker_credentials_json": {
               "redacted_message": "[PRIVATE DATA HIDDEN]"
            },
            "ports": [
               8080
            ],
            "space_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1",
            "stack_url": "/v2/stacks/2c531037-68a2-4e2c-a9e0-71f9d0abf0d4",
            "events_url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/events",
            "service_bindings_url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/service_bindings",
            "routes_url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/routes"
         }
      }
   ]
}`

const listAppsPayloadPage2 = `{
   "total_results": 28,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "f9ad202b-76dd-44ec-b7c2-fd2417a561e8",
            "url": "/v2/apps/f9ad202b-76dd-44ec-b7c2-fd2417a561e8",
            "created_at": "2014-10-10T21:03:13+00:00",
            "updated_at": "2014-11-10T14:07:31+00:00"
         },
         "entity": {
            "name": "app-test2",
            "production": false,
            "space_guid": "8efd7c5c-d83c-4786-b399-b7bd548839e1",
            "stack_guid": "2c531037-68a2-4e2c-a9e0-71f9d0abf0d4",
            "buildpack": "https://github.com/cloudfoundry/buildpack-go.git",
            "detected_buildpack": null,
            "environment_json": {
               "FOOBAR": "QUX"
            },
            "memory": 256,
            "instances": 1,
            "disk_quota": 1024,
            "state": "STARTED",
            "version": "97ef1272-9eb6-4839-9df1-5ed4f55b5c45",
            "command": null,
            "console": false,
            "debug": null,
            "staging_task_id": "5879c8d06a10491a879734162000def8",
            "package_state": "PENDING",
            "health_check_timeout": null,
            "staging_failed_reason": null,
            "docker_image": null,
            "package_updated_at": "2014-11-10T14:08:50+00:00",
            "detected_start_command": "app-launching-service-broker",
            "space_url": "/v2/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1",
            "stack_url": "/v2/stacks/2c531037-68a2-4e2c-a9e0-71f9d0abf0d4",
            "events_url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/events",
            "service_bindings_url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/service_bindings",
            "routes_url": "/v2/apps/af15c29a-6bde-4a9b-8cdf-43aa0d4b7e3c/routes"
         }
      }
   ]
}`

const appPayload = `{
   "metadata": {
      "guid": "9902530c-c634-4864-a189-71d763cb12e2",
      "url": "/v2/apps/9902530c-c634-4864-a189-71d763cb12e2",
      "created_at": "2014-11-07T23:11:39+00:00",
      "updated_at": "2014-11-07T23:12:03+00:00"
   },
   "entity": {
      "name": "test-env",
      "production": false,
      "space_guid": "a72fa1e8-c694-47b3-85f2-55f61fd00d73",
      "stack_guid": "2c531037-68a2-4e2c-a9e0-71f9d0abf0d4",
      "buildpack": null,
      "detected_buildpack": "Ruby",
      "environment_json": {},
      "memory": 256,
      "instances": 1,
      "disk_quota": 1024,
      "state": "STARTED",
      "version": "0d2f5607-ab6a-4abd-91fe-222cde1ea0f8",
      "command": null,
      "console": false,
      "debug": null,
      "staging_task_id": "46267d4a98ae4f4390aed29975453d60",
      "package_state": "STAGED",
      "health_check_timeout": null,
      "staging_failed_reason": null,
      "docker_image": null,
      "package_updated_at": "2014-11-07T23:12:58+00:00",
      "detected_start_command": "rackup -p $PORT",
      "space_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73",
      "stack_url": "/v2/stacks/2c531037-68a2-4e2c-a9e0-71f9d0abf0d4",
      "events_url": "/v2/apps/9902530c-c634-4864-a189-71d763cb12e2/events",
      "service_bindings_url": "/v2/apps/9902530c-c634-4864-a189-71d763cb12e2/service_bindings",
      "routes_url": "/v2/apps/9902530c-c634-4864-a189-71d763cb12e2/routes"
   }
}`

const appEnvPayload = `{
  "staging_env_json": {
    "STAGING_ENV": "staging_value"
  },
  "running_env_json": {
    "RUNNING_ENV": "running_value"
  },
  "environment_json": {
    "env_var": "env_val"
  },
  "system_env_json": {
    "VCAP_SERVICES": {
      "abc": 123
    }
  },
  "application_env_json": {
    "VCAP_APPLICATION": {
      "limits": {
        "fds": 16384,
        "mem": 1024,
        "disk": 1024
      },
      "application_name": "name-2245",
      "application_uris": [

      ],
      "name": "name-2245",
      "space_name": "name-2246",
      "space_id": "3309d44f-78ae-4058-99e1-c50469d1e043",
      "uris": [

      ],
      "users": null,
      "application_id": "a7c47787-a982-467c-95d7-9ab17cbcc918",
      "version": "ed59723c-d691-4d4f-ac5b-f174266c988f",
      "application_version": "ed59723c-d691-4d4f-ac5b-f174266c988f"
    }
  }
}`

const appPayloadWithEnvironment_json = `{
   "metadata": {
   },
   "entity": {
      "environment_json": {"string": "string", "int": 1}
   }
}`

const appInstancePayload = `{
   "0": {
      "state": "RUNNING",
      "since": 1455210430.5104606,
      "debug_ip": null,
      "debug_port": null,
      "console_ip": null,
      "console_port": null
   },
   "1": {
      "state": "RUNNING",
      "since": 1455210430.3912115,
      "debug_ip": null,
      "debug_port": null,
      "console_ip": null,
      "console_port": null
   }
}`

const appInstanceUnhealthyPayload = `{
   "0": {
      "state": "RUNNING",
      "since": 1455210430.5104606,
      "debug_ip": null,
      "debug_port": null,
      "console_ip": null,
      "console_port": null
   },
   "1": {
      "state": "STARTING",
      "since": 1455210430.3912115,
      "debug_ip": null,
      "debug_port": null,
      "console_ip": null,
      "console_port": null
   }
}`

const appStatsPayload = `{
   "0": {
      "state": "RUNNING",
      "stats": {
         "name": "example-app",
         "uris": [
            "example-app.example.com",
            "example-app-route2.example.com"
         ],
         "host": "192.168.1.100",
         "port": 61297,
         "uptime": 411118,
         "mem_quota": 536870912,
         "disk_quota": 1073741824,
         "fds_quota": 16384,
         "usage": {
            "time": "2016-09-17 15:46:17 +0000",
            "cpu": 0.36580239597146486,
            "mem": 518123520,
            "disk": 151150592
         }
      }
   },
   "1": {
      "state": "RUNNING",
      "stats": {
         "name": "example-app",
         "uris": [
            "example-app.example.com",
            "example-app-route2.example.com"
         ],
         "host": "192.168.1.101",
         "port": 61388,
         "uptime": 419568,
         "mem_quota": 536870912,
         "disk_quota": 1073741824,
         "fds_quota": 16384,
         "usage": {
            "time": "2016-09-17T15:46:17Z",
            "cpu": 0.33857742931636664,
            "mem": 530731008,
            "disk": 151150592
         }
      }
   },
   "2": {
      "state": "RUNNING",
      "stats": {
         "name": "example-app",
         "uris": [
            "example-app.example.com",
            "example-app-route2.example.com"
         ],
         "host": "192.168.1.102",
         "port": 61389,
         "uptime": 419568,
         "mem_quota": 536870912,
         "disk_quota": 1073741824,
         "fds_quota": 16384,
         "usage": {
            "time": "2017-04-06T20:32:19.273294439Z",
            "cpu": 0.33857742931636664,
            "mem": 530731008,
            "disk": 151150592
         }
      }
   },
   "3": {
      "state": "RUNNING",
      "stats": {
         "name": "example-app",
         "uris": [
            "example-app.example.com",
            "example-app-route2.example.com"
         ],
         "host": "192.168.1.102",
         "port": 61389,
         "uptime": 419568,
         "mem_quota": 536870912,
         "disk_quota": 1073741824,
         "fds_quota": 16384,
         "usage": {
            "time": "2017-04-12 15:27:44 UTC",
            "cpu": 0.33857742931636664,
            "mem": 530731008,
            "disk": 151150592
         }
      }
   }
}`

const appRoutesPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "311d34d1-c045-4853-845f-05132377ad7d",
        "url": "/v2/routes/311d34d1-c045-4853-845f-05132377ad7d",
        "created_at": "2016-06-08T16:41:44Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "host": "host-36",
        "path": "/foo",
        "domain_guid": "40a499f7-198a-4289-9aa2-605ba43f92ee",
        "space_guid": "c7c0dd06-b078-43d7-adcb-3974cd785fdd",
        "service_instance_guid": null,
        "port": null,
        "domain_url": "/v2/private_domains/40a499f7-198a-4289-9aa2-605ba43f92ee",
        "space_url": "/v2/spaces/c7c0dd06-b078-43d7-adcb-3974cd785fdd",
        "apps_url": "/v2/routes/311d34d1-c045-4853-845f-05132377ad7d/apps",
        "route_mappings_url": "/v2/routes/311d34d1-c045-4853-845f-05132377ad7d/route_mappings"
      }
    }
  ]
}`

const spacePayload = `{
   "metadata": {
      "guid": "a72fa1e8-c694-47b3-85f2-55f61fd00d73",
      "url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73",
      "created_at": "2014-11-03T16:47:24+00:00",
      "updated_at": null
   },
   "entity": {
      "name": "test-space",
      "organization_guid": "da0dba14-6064-4f7a-b15a-ff9e677e49b2",
      "space_quota_definition_guid": null,
      "organization_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2",
      "developers_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/developers",
      "managers_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/managers",
      "auditors_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/auditors",
      "apps_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/apps",
      "routes_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/routes",
      "domains_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/domains",
      "service_instances_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/service_instances",
      "app_events_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/app_events",
      "events_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/events",
      "security_groups_url": "/v2/spaces/a72fa1e8-c694-47b3-85f2-55f61fd00d73/security_groups"
   }
}`

const orgPayload = `{
   "metadata": {
      "guid": "da0dba14-6064-4f7a-b15a-ff9e677e49b2",
      "url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2",
      "created_at": "2014-09-26T13:36:41+00:00",
      "updated_at": null
   },
   "entity": {
      "name": "test-org",
      "billing_enabled": false,
      "quota_definition_guid": "183599e0-d535-4559-8675-7b6ddb5cc42d",
      "status": "active",
      "quota_definition_url": "/v2/quota_definitions/183599e0-d535-4559-8675-7b6ddb5cc42d",
      "spaces_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/spaces",
      "domains_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/domains",
      "private_domains_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/private_domains",
      "users_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/users",
      "managers_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/managers",
      "billing_managers_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/billing_managers",
      "auditors_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/auditors",
      "app_events_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/app_events",
      "space_quota_definitions_url": "/v2/organizations/da0dba14-6064-4f7a-b15a-ff9e677e49b2/space_quota_definitions"
   }
}`

const listServiceBindingsPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "aa599bb3-4811-405a-bbe3-a68c7c55afc8",
        "url": "/v2/service_bindings/aa599bb3-4811-405a-bbe3-a68c7c55afc8",
        "created_at": "2016-06-08T16:41:43Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "app_guid": "b26e7e98-f002-41a8-a663-1b60f808a92a",
        "service_instance_guid": "bde206e0-1ee8-48ad-b794-44c857633d50",
        "credentials": {
          "creds-key-66": "creds-val-66"
        },
        "binding_options": {

        },
        "gateway_data": null,
        "gateway_name": "",
        "syslog_drain_url": null,
        "volume_mounts": [

        ],
        "app_url": "/v2/apps/b26e7e98-f002-41a8-a663-1b60f808a92a",
        "service_instance_url": "/v2/service_instances/bde206e0-1ee8-48ad-b794-44c857633d50"
      }
    }
  ]
}`

const serviceBindingByGuidPayload = `{
  "metadata": {
    "guid": "foo-bar-baz",
    "url": "/v2/service_bindings/foo-bar-baz",
    "created_at": "2017-06-22T03:46:24Z",
    "updated_at": "2017-06-22T03:46:24Z"
  },
  "entity": {
    "app_guid": "app-bar-baz",
    "service_instance_guid": "instance-bar-baz",
    "credentials": {
      "host": "host.bar.baz",
      "port": 5432
    },
    "binding_options": {
    },
    "gateway_data": null,
    "gateway_name": "",
    "syslog_drain_url": null,
    "volume_mounts": [
    ],
    "app_url": "/v2/apps/app-bar-baz",
    "service_instance_url": "/v2/service_instances/instance-bar-baz"
  }
}
`

const listServicePlansPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "6fecf53b-7553-4cb3-b97e-930f9c4e3385",
        "url": "/v2/service_plans/6fecf53b-7553-4cb3-b97e-930f9c4e3385",
        "created_at": "2016-06-08T16:41:30Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name-1575",
        "free": false,
        "description": "desc-109",
        "service_guid": "1ccab853-87c9-45a6-bf99-603032d17fe5",
        "extra": null,
        "unique_id": "1bc2884c-ee3d-4f82-a78b-1a657f79aeac",
        "public": true,
        "active": true,
        "bindable": true,
        "service_url": "/v2/services/1ccab853-87c9-45a6-bf99-603032d17fe5",
        "service_instances_url": "/v2/service_plans/6fecf53b-7553-4cb3-b97e-930f9c4e3385/service_instances"
      }
    }
  ]
}`

const listServicePayload = `{
   "total_results": 22,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "a3d76c01-c08a-4505-b06d-8603265682a3",
            "url": "/v2/services/a3d76c01-c08a-4505-b06d-8603265682a3",
            "created_at": "2014-09-24T14:10:51+00:00",
            "updated_at": "2014-10-08T00:06:30+00:00"
         },
         "entity": {
            "label": "nats",
            "provider": null,
            "url": null,
            "description": "NATS is a lightweight cloud messaging system",
            "long_description": null,
            "version": null,
            "info_url": null,
            "active": true,
            "bindable": true,
            "unique_id": "b9310aba-2fa4-11e4-b626-a6c5e4d22fb7",
            "extra": "",
            "tags": [
               "nats",
               "mbus",
               "pubsub"
            ],
            "requires": [],
            "documentation_url": null,
            "service_broker_guid": "a4bdf03a-f0c4-43f9-9c77-f434da91404f",
            "plan_updateable": false,
            "service_plans_url": "/v2/services/a3d76c01-c08a-4505-b06d-8603265682a3/service_plans"
         }
      },
      {
         "metadata": {
            "guid": "ab9ad9c8-1f51-463a-ae3a-5082e9f04ae6",
            "url": "/v2/services/ab9ad9c8-1f51-463a-ae3a-5082e9f04ae6",
            "created_at": "2014-09-24T14:10:51+00:00",
            "updated_at": "2014-10-08T00:06:30+00:00"
         },
         "entity": {
            "label": "etcd",
            "provider": null,
            "url": null,
            "description": "Etcd key-value storage",
            "long_description": null,
            "version": null,
            "info_url": null,
            "active": true,
            "bindable": true,
            "unique_id": "211411a0-2da1-11e4-852f-a6c5e4d22fb7",
            "extra": "",
            "tags": [
               "etcd",
               "keyvalue",
               "etcd-0.4.6"
            ],
            "requires": [],
            "documentation_url": null,
            "service_broker_guid": "a4bdf03a-f0c4-43f9-9c77-f434da91404f",
            "plan_updateable": false,
            "service_plans_url": "/v2/services/ab9ad9c8-1f51-463a-ae3a-5082e9f04ae6/service_plans"
         }
      }
   ]
}`

const listServicePlanVisibilitiesPayload = `{
  "total_results": 4,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "d1b5ea55-f354-4f43-b52e-53045747adb9",
        "url": "/v2/service_plan_visibilities/d1b5ea55-f354-4f43-b52e-53045747adb9",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "service_plan_guid": "62cb572c-e9ca-4c9f-b822-8292db1d9a96",
        "organization_guid": "81df84f3-8ce0-4c92-990a-3760b6ff66bd",
        "service_plan_url": "/v2/service_plans/62cb572c-e9ca-4c9f-b822-8292db1d9a96",
        "organization_url": "/v2/organizations/81df84f3-8ce0-4c92-990a-3760b6ff66bd"
      }
    },
    {
      "metadata": {
        "guid": "332331a3-7b6c-413b-a2e4-edf90ac47fa9",
        "url": "/v2/service_plan_visibilities/332331a3-7b6c-413b-a2e4-edf90ac47fa9",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "service_plan_guid": "c505f2ec-81ed-4091-b194-b8e905f32b24",
        "organization_guid": "99b61b74-09d6-47db-9568-a835e42d0a1d",
        "service_plan_url": "/v2/service_plans/c505f2ec-81ed-4091-b194-b8e905f32b24",
        "organization_url": "/v2/organizations/99b61b74-09d6-47db-9568-a835e42d0a1d"
      }
    }
  ]
}`

const postServicePlanVisibilityPayload = `{
  "metadata": {
    "guid": "f740b01a-4afe-4435-aedd-0a8308a7e7d6",
    "url": "/v2/service_plan_visibilities/f740b01a-4afe-4435-aedd-0a8308a7e7d6",
    "created_at": "2016-06-08T16:41:31Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "service_plan_guid": "ab5780a9-ac8e-4412-9496-4512e865011a",
    "organization_guid": "55d0ff39-dac9-431f-ba6d-83f37381f1c3",
    "service_plan_url": "/v2/service_plans/ab5780a9-ac8e-4412-9496-4512e865011a",
    "organization_url": "/v2/organizations/55d0ff39-dac9-431f-ba6d-83f37381f1c3"
  }
}`

const listAppsCreatedEventPayload = `{
   "total_results": 3,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/events2",
   "resources": [
      {
         "metadata": {
            "guid": "49ab122b-82b9-4623-8a13-24e585e32e66",
            "url": "/v2/events/49ab122b-82b9-4623-8a13-24e585e32e66",
            "created_at": "2016-02-26T13:00:21Z",
            "updated_at": null
         },
         "entity": {
            "type": "audit.app.update",
            "actor": "fbf30c43-436e-40e4-8ace-31970b52ce89",
            "actor_type": "user",
            "actor_name": "team-toad@sap.com",
            "actee": "3ca436ff-67a8-468a-8c7d-27ec68a6cfe5",
            "actee_type": "app",
            "actee_name": "authentication-v1-pre-blue",
            "timestamp": "2016-02-26T13:00:21Z",
            "metadata": {
               "request": {
                  "state": "STOPPED"
               }
            },
            "space_guid": "08582a96-cbef-463c-822e-bda8d4284cc7",
            "organization_guid": "bfdcdf09-a3b8-46f4-ab74-d494efefe5b4"
         }
      },
      {
         "metadata": {
            "guid": "49ab122b-82b9-4623-8a13-24e585e32e66",
            "url": "/v2/events/49ab122b-82b9-4623-8a13-24e585e32e66",
            "created_at": "2016-02-26T13:00:21Z",
            "updated_at": "2016-02-26T13:00:21Z"
         },
         "entity": {
            "type": "app.crash",
            "actor": "fbf30c43-436e-40e4-8ace-31970b52ce89",
            "actor_type": "app",
            "actor_name": "authentication-v1-pre-blue",
            "actee": "3ca436ff-67a8-468a-8c7d-27ec68a6cfe5",
            "actee_type": "app",
            "actee_name": "authentication-v1-pre-blue",
            "timestamp": "2016-02-26T13:00:21Z",
            "metadata": {
             "instance": "",
             "index": 0,
             "exit_description": "2 error(s) occurred:\n\n* 1 error(s) occurred:\n\n* Exited with status 4\n* 2 error(s) occurred:\n\n* cancelled\n* cancelled",
             "reason": "CRASHED"
            },
            "space_guid": "08582a96-cbef-463c-822e-bda8d4284cc7",
            "organization_guid": "bfdcdf09-a3b8-46f4-ab74-d494efefe5b4"
         }
      }
   ]
 }`
const listAppsCreatedEventPayload2 = `{
   "total_results": 3,
   "total_pages": 2,
   "prev_url": "/v2/events",
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "8e8f83c7-3fc3-4127-9359-ae391380b971",
            "url": "/v2/events/8e8f83c7-3fc3-4127-9359-ae391380b971",
            "created_at": "2016-02-26T13:00:21Z",
            "updated_at": null
         },
         "entity": {
            "type": "audit.app.update",
            "actor": "fbf30c43-436e-40e4-8ace-31970b52ce89",
            "actor_type": "user",
            "actor_name": "team-toad@sap.com",
            "actee": "3ca436ff-67a8-468a-8c7d-27ec68a6cfe5",
            "actee_type": "app",
            "actee_name": "authentication-v1-pre-blue",
            "timestamp": "2016-02-26T13:00:21Z",
            "metadata": {
               "request": {
                  "health_check_timeout": 180,
                  "buildpack": "nodejs_buildpack",
                  "command": "PRIVATE DATA HIDDEN",
                  "state": "STARTED"
               }
            },
            "space_guid": "08582a96-cbef-463c-822e-bda8d4284cc7",
            "organization_guid": "bfdcdf09-a3b8-46f4-ab74-d494efefe5b4"
         }
      }
    ]
 }`

var serviceInstancePayload = `{
   "metadata": {
      "guid": "8423ca96-90ad-411f-b77a-0907844949fc",
      "url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc",
      "created_at": "2016-10-21T18:22:56Z",
      "updated_at": null
   },
   "entity": {
      "name": "fortunes-db",
      "credentials": {},
      "service_guid": "440ce9d9-b108-4bbe-80b4-08338f3cc25b",
      "service_plan_guid": "f48419f7-4717-4706-86e4-a24973848a77",
      "space_guid": "21e5fdc7-5131-4743-8447-6373cf336a77",
      "gateway_data": null,
      "dashboard_url": "https://p-mysql.system.example.com/manage/instances/8423ca96-90ad-411f-b77a-0907844949fc",
      "type": "managed_service_instance",
      "last_operation": {
         "type": "create",
         "state": "succeeded",
         "description": "",
         "updated_at": null,
         "created_at": "2016-10-21T18:22:56Z"
      },
      "tags": [],
      "space_url": "/v2/spaces/21e5fdc7-5131-4743-8447-6373cf336a77",
      "service_plan_url": "/v2/service_plans/f48419f7-4717-4706-86e4-a24973848a77",
      "service_bindings_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/service_bindings",
      "service_keys_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/service_keys",
      "routes_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/routes",
      "service_url": "/v2/services/440ce9d9-b108-4bbe-80b4-08338f3cc25b"
   }
}`

var listServiceInstancePayload = `{
  "total_results": 2,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "8423ca96-90ad-411f-b77a-0907844949fc",
        "url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc",
        "created_at": "2016-10-21T18:22:56Z",
        "updated_at": null
      },
      "entity": {
        "name": "fortunes-db",
        "credentials": {},
        "service_guid": "440ce9d9-b108-4bbe-80b4-08338f3cc25b",
        "service_plan_guid": "f48419f7-4717-4706-86e4-a24973848a77",
        "space_guid": "21e5fdc7-5131-4743-8447-6373cf336a77",
        "gateway_data": null,
        "dashboard_url": "https://p-mysql.system.example.com/manage/instances/8423ca96-90ad-411f-b77a-0907844949fc",
        "type": "managed_service_instance",
        "last_operation": {
          "type": "create",
          "state": "succeeded",
          "description": "",
          "updated_at": null,
          "created_at": "2016-10-21T18:22:56Z"
        },
        "tags": [],
        "space_url": "/v2/spaces/21e5fdc7-5131-4743-8447-6373cf336a77",
        "service_plan_url": "/v2/service_plans/f48419f7-4717-4706-86e4-a24973848a77",
        "service_bindings_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/service_bindings",
        "service_keys_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/service_keys",
        "routes_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/routes",
        "service_url": "/v2/services/440ce9d9-b108-4bbe-80b4-08338f3cc25b"
      }
    },
    {
      "metadata": {
        "guid": "8423ca96-90ad-411f-b77a-0907844949fc",
        "url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc",
        "created_at": "2016-10-21T18:22:56Z",
        "updated_at": null
      },
      "entity": {
        "name": "fortunes-db",
        "credentials": {},
        "service_guid": "440ce9d9-b108-4bbe-80b4-08338f3cc25b",
        "service_plan_guid": "f48419f7-4717-4706-86e4-a24973848a77",
        "space_guid": "21e5fdc7-5131-4743-8447-6373cf336a77",
        "gateway_data": null,
        "dashboard_url": "https://p-mysql.system.example.com/manage/instances/8423ca96-90ad-411f-b77a-0907844949fc",
        "type": "managed_service_instance",
        "last_operation": {
          "type": "create",
          "state": "succeeded",
          "description": "",
          "updated_at": null,
          "created_at": "2016-10-21T18:22:56Z"
        },
        "tags": [],
        "space_url": "/v2/spaces/21e5fdc7-5131-4743-8447-6373cf336a77",
        "service_plan_url": "/v2/service_plans/f48419f7-4717-4706-86e4-a24973848a77",
        "service_bindings_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/service_bindings",
        "service_keys_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/service_keys",
        "routes_url": "/v2/service_instances/8423ca96-90ad-411f-b77a-0907844949fc/routes",
        "service_url": "/v2/services/440ce9d9-b108-4bbe-80b4-08338f3cc25b"
      }
    }
  ]
}`

const userProvidedServiceInstancePayload = `{
  "metadata": {
    "guid": "e9358711-0ad9-4f2a-b3dc-289d47c17c87",
    "url": "/v2/user_provided_service_instances/e9358711-0ad9-4f2a-b3dc-289d47c17c87",
    "created_at": "2016-06-08T16:41:33Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "name-1700",
    "credentials": {
      "creds-key-58": "creds-val-58"
    },
    "space_guid": "22236d1a-d9c7-44b7-bdad-2bb079a6c4a1",
    "type": "user_provided_service_instance",
    "syslog_drain_url": "https://foo.com/url-104",
    "route_service_url": null,
    "space_url": "/v2/spaces/22236d1a-d9c7-44b7-bdad-2bb079a6c4a1",
    "service_bindings_url": "/v2/user_provided_service_instances/e9358711-0ad9-4f2a-b3dc-289d47c17c87/service_bindings",
    "routes_url": "/v2/user_provided_service_instances/e9358711-0ad9-4f2a-b3dc-289d47c17c87/routes"
  }
}`

const listUserProvidedServiceInstancePayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "54e4c645-7d20-4271-8c27-8cc904e1e7ee",
        "url": "/v2/user_provided_service_instances/54e4c645-7d20-4271-8c27-8cc904e1e7ee",
        "created_at": "2016-06-08T16:41:33Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name-1696",
        "credentials": {
          "creds-key-57": "creds-val-57"
        },
        "space_guid": "87d14ac2-f396-460e-a523-dc1d77aba35a",
        "type": "user_provided_service_instance",
        "syslog_drain_url": "https://foo.com/url-103",
        "route_service_url": null,
        "space_url": "/v2/spaces/87d14ac2-f396-460e-a523-dc1d77aba35a",
        "service_bindings_url": "/v2/user_provided_service_instances/54e4c645-7d20-4271-8c27-8cc904e1e7ee/service_bindings",
        "routes_url": "/v2/user_provided_service_instances/54e4c645-7d20-4271-8c27-8cc904e1e7ee/routes"
      }
    }
  ]
}`

const listRoutesPayloadPage1 string = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/routes_page_2",
   "resources": [
      {
         "metadata": {
            "guid": "24707add-83b8-4fd8-a8f4-b7297199c805",
            "url": "/v2/routes/24707add-83b8-4fd8-a8f4-b7297199c805",
            "created_at": "2017-02-06T14:13:57Z",
            "updated_at": "2017-02-06T14:13:57Z"
         },
         "entity": {
            "host": "test-1",
            "path": "/foo",
            "domain_guid": "0b183484-45cc-4855-94d4-892f80f20c13",
            "space_guid": "494d8b64-8181-4183-a6d3-6279db8fec6e",
            "service_instance_guid": null,
            "port": null,
            "domain_url": "/v2/shared_domains/0b183484-45cc-4855-94d4-892f80f20c13",
            "space_url": "/v2/spaces/494d8b64-8181-4183-a6d3-6279db8fec6e",
            "apps_url": "/v2/routes/24707add-83b8-4fd8-a8f4-b7297199c805/apps",
            "route_mappings_url": "/v2/routes/24707add-83b8-4fd8-a8f4-b7297199c805/route_mappings"
         }
      }
   ]
}`

const listRoutesPayloadPage2 string = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "1aba0d30-eb57-4543-a805-0d1c77171b4d",
            "url": "/v2/routes/1aba0d30-eb57-4543-a805-0d1c77171b4d",
            "created_at": "2017-02-07T03:57:17Z",
            "updated_at": "2017-02-07T03:57:17Z"
         },
         "entity": {
            "host": "test-2",
            "path": "",
            "domain_guid": "0b183484-45cc-4855-94d4-892f80f20c13",
            "space_guid": "494d8b64-8181-4183-a6d3-6279db8fec6e",
            "service_instance_guid": null,
            "port": null,
            "domain_url": "/v2/shared_domains/0b183484-45cc-4855-94d4-892f80f20c13",
            "space_url": "/v2/spaces/494d8b64-8181-4183-a6d3-6279db8fec6e",
            "apps_url": "/v2/routes/1aba0d30-eb57-4543-a805-0d1c77171b4d/apps",
            "route_mappings_url": "/v2/routes/1aba0d30-eb57-4543-a805-0d1c77171b4d/route_mappings"
         }
      }
   ]
}`

const createRoute string = `
{
  "metadata": {
    "guid": "78fe5006-1d1c-41ba-94de-eb7002241b82",
    "url": "/v2/routes/78fe5006-1d1c-41ba-94de-eb7002241b82",
    "created_at": "2017-05-24T19:04:34Z",
    "updated_at": null
  },
  "entity": {
    "host": "",
    "path": "",
    "domain_guid": "08167353-32da-4ed9-9ef5-aa7b31bbc009",
    "space_guid": "b65a9a76-8c55-460b-9162-18b396da66cf",
    "service_instance_guid": null,
    "port": 1099,
    "domain_url": "/v2/shared_domains/08167353-32da-4ed9-9ef5-aa7b31bbc009",
    "domain": {
      "metadata": {
        "guid": "08167353-32da-4ed9-9ef5-aa7b31bbc009",
        "url": "/v2/shared_domains/08167353-32da-4ed9-9ef5-aa7b31bbc009",
        "created_at": "2017-01-17T17:54:46Z",
        "updated_at": null
      },
      "entity": {
        "name": "tcp.main.example.com",
        "router_group_guid": "b4c90165-5689-4a7e-4cfc-f55dc41f3e22",
        "router_group_type": null
      }
    },
    "space_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf",
    "space": {
      "metadata": {
        "guid": "b65a9a76-8c55-460b-9162-18b396da66cf",
        "url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf",
        "created_at": "2016-12-09T15:06:17Z",
        "updated_at": null
      },
      "entity": {
        "name": "system",
        "organization_guid": "236c6d93-7cfb-4d4a-bc76-9a9cc2bc8e58",
        "space_quota_definition_guid": null,
        "allow_ssh": true,
        "organization_url": "/v2/organizations/236c6d93-7cfb-4d4a-bc76-9a9cc2bc8e58",
        "developers_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/developers",
        "managers_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/managers",
        "auditors_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/auditors",
        "apps_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/apps",
        "routes_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/routes",
        "domains_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/domains",
        "service_instances_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/service_instances",
        "app_events_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/app_events",
        "events_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/events",
        "security_groups_url": "/v2/spaces/b65a9a76-8c55-460b-9162-18b396da66cf/security_groups"
      }
    },
    "apps_url": "/v2/routes/78fe5006-1d1c-41ba-94de-eb7002241b82/apps",
    "apps": [

    ],
    "route_mappings_url": "/v2/routes/78fe5006-1d1c-41ba-94de-eb7002241b82/route_mappings"
  }
}`

const listStacksPayloadPage1 string = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/stacks_page_2",
   "resources": [
      {
         "metadata": {
            "guid": "67e019a3-322a-407a-96e0-178e95bd0e55",
            "url": "/v2/stacks/67e019a3-322a-407a-96e0-178e95bd0e55",
            "created_at": "2017-01-18T16:39:11Z",
            "updated_at": "2017-01-18T16:39:11Z"
         },
         "entity": {
            "name": "cflinuxfs2",
            "description": "Cloud Foundry Linux-based filesystem"
         }
      }
   ]
}`

const listStacksPayloadPage2 string = `{
   "total_results": 2,
   "total_pages": 2,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "a9be2e10-0164-401d-94e0-88455d614844",
            "url": "/v2/stacks/a9be2e10-0164-401d-94e0-88455d614844",
            "created_at": "2017-01-18T16:39:11Z",
            "updated_at": "2017-01-18T16:39:11Z"
         },
         "entity": {
            "name": "windows2012R2",
            "description": "Experimental Windows runtime"
         }
      }
   ]
}`

const listTasksPayload string = `
{
"pagination": {
"total_results": 2,
"total_pages": 1,
"first": {
"href": "https://api.run.example.com/v3/tasks?page=1&per_page=50"
},
"last": {
"href": "https://api.run.example.com/v3/tasks?page=1&per_page=50"
},
"next": null,
"previous": null
},
"resources": [
{
"guid": "xxxxxxxx-e99c-4d60-xxx-e066eb45f8a7",
"sequence_id": 1,
"name": "xxxxxxxx",
"state": "FAILED",
"memory_in_mb": 1024,
"disk_in_mb": 1024,
"result": {
"failure_reason": "Exited with status 127"
},
"created_at": "2016-12-22T13:24:20Z",
"updated_at": "2016-12-22T13:24:25Z",
"droplet_guid": "xxxxxxxx-6cae-49b0-xxxxx-9265950fc16b",
"links": {
"self": {
"href": "https://api.run.example.com/v3/tasks/xxxxxxxx-e99c-4d60-xxxxx-e066eb45f8a7"
},
"app": {
"href": "https://api.run.example.com/v3/apps/xxxxxxxxx-1b30-4e4d-xxxxx-44dec11e3d5b"
},
"droplet": {
"href": "https://api.run.example.com/v3/droplets/xxxxxxxxx-6cae-490b-xxxxx-9265950fc16b"
}
}
},
{
"guid": "xxxxxxxx-5a25-4110-xxx-b309dc5cb0aa",
"sequence_id": 2,
"name": "yyyyyyyyy",
"state": "FAILED",
"memory_in_mb": 1024,
"disk_in_mb": 1024,
"result": {
"failure_reason": "Exited with status 127"
},
"created_at": "2016-12-22T13:24:36Z",
"updated_at": "2016-12-22T13:24:42Z",
"droplet_guid": "xxxxxxx-6cae-49b0-xxxx-9265950fc16b",
"links": {
"self": {
"href": "https://api.run.example.com/v3/tasks/xxxxxxxxx-5a25-4110-xxxxx-b309dc5cb0aa"
},
"app": {
"href": "https://api.run.example.com/v3/apps/xxxxxxxxx-1b30-4e4d-xxxxx-44dec11e3d5b"
},
"droplet": {
"href": "https://api.run.example.com/v3/droplets/xxxxxxxx-6cae-490b-xxxxx-9265950fc16b"
}
}
}
]
}
`

const createTaskPayload = `
{
  "guid": "d5cc22ec-99a3-4e6a-af91-a44b4ab7b6fa",
  "sequence_id": 1,
  "name": "migrate",
  "command": "rake db:migrate",
  "state": "RUNNING",
  "memory_in_mb": 512,
  "disk_in_mb": 1024,
  "result": {
    "failure_reason": null
  },
  "droplet_guid": "740ebd2b-162b-469a-bd72-3edb96fabd9a",
  "created_at": "2016-05-04T17:00:41Z",
  "updated_at": "2016-05-04T17:00:42Z",
  "links": {
    "self": {
      "href": "https://api.example.org/v3/tasks/d5cc22ec-99a3-4e6a-af91-a44b4ab7b6fa"
    },
    "app": {
      "href": "https://api.example.org/v3/apps/ccc25a0f-c8f4-4b39-9f1b-de9f328d0ee5"
    },
    "droplet": {
      "href": "https://api.example.org/v3/droplets/740ebd2b-162b-469a-bd72-3edb96fabd9a"
    }
  }
}
`
const listDomainsPayload = `{
  "total_results": 4,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "b2a35f0c-d5ad-4a59-bea7-461711d96b0d",
        "url": "/v2/private_domains/b2a35f0c-d5ad-4a59-bea7-461711d96b0d",
        "created_at": "2016-06-08T16:41:39Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "vcap.me",
        "owning_organization_guid": "4cf3bc47-eccd-4662-9322-7833c3bdcded",
        "owning_organization_url": "/v2/organizations/4cf3bc47-eccd-4662-9322-7833c3bdcded",
        "shared_organizations_url": "/v2/private_domains/b2a35f0c-d5ad-4a59-bea7-461711d96b0d/shared_organizations"
      }
    },
    {
      "metadata": {
        "guid": "28db6393-cc6f-4318-a63c-f4009e8842bc",
        "url": "/v2/private_domains/28db6393-cc6f-4318-a63c-f4009e8842bc",
        "created_at": "2016-06-08T16:41:39Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "domain-61.example.com",
        "owning_organization_guid": "c262280e-0ccc-4e13-918a-6852f2d1e3a0",
        "owning_organization_url": "/v2/organizations/c262280e-0ccc-4e13-918a-6852f2d1e3a0",
        "shared_organizations_url": "/v2/private_domains/28db6393-cc6f-4318-a63c-f4009e8842bc/shared_organizations"
      }
    },
    {
      "metadata": {
        "guid": "a16ffec7-5fab-4447-861e-c38da6548c6d",
        "url": "/v2/private_domains/a16ffec7-5fab-4447-861e-c38da6548c6d",
        "created_at": "2016-06-08T16:41:39Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "domain-62.example.com",
        "owning_organization_guid": "68f69961-f751-4b52-907c-4469009fdf74",
        "owning_organization_url": "/v2/organizations/68f69961-f751-4b52-907c-4469009fdf74",
        "shared_organizations_url": "/v2/private_domains/a16ffec7-5fab-4447-861e-c38da6548c6d/shared_organizations"
      }
    },
    {
      "metadata": {
        "guid": "4168cdaf-1586-41a6-9e5f-d8c715c332f5",
        "url": "/v2/private_domains/4168cdaf-1586-41a6-9e5f-d8c715c332f5",
        "created_at": "2016-06-08T16:41:39Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "domain-63.example.com",
        "owning_organization_guid": "8d8ed1ba-f7f3-48f1-8d9a-2dfaad91335b",
        "owning_organization_url": "/v2/organizations/8d8ed1ba-f7f3-48f1-8d9a-2dfaad91335b",
        "shared_organizations_url": "/v2/private_domains/4168cdaf-1586-41a6-9e5f-d8c715c332f5/shared_organizations"
      }
    }
  ]
}`

const listSharedDomainsPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "91977695-8ad9-40db-858f-4df782603ec3",
        "url": "/v2/shared_domains/91977695-8ad9-40db-858f-4df782603ec3",
        "created_at": "2016-06-08T16:41:37Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "domain-49.example.com",
        "router_group_guid": "my-random-guid",
        "router_group_type": "tcp"
      }
    }
  ]
}`

const listDomainsEmptyResponse = `{
  "total_results": 0,
  "total_pages": 0,
  "prev_url": null,
  "next_url": null,
  "resources": []
}`

const postDomainPayload = `{
  "metadata": {
    "guid": "b98aeca1-22b9-49f9-8428-3ace9ea2ba11",
    "url": "/v2/private_domains/b98aeca1-22b9-49f9-8428-3ace9ea2ba11",
    "created_at": "2016-06-08T16:41:39Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "name": "exmaple.com",
    "owning_organization_guid": "8483e4f1-d3a3-43e2-ab8c-b05ea40ef8db",
    "owning_organization_url": "/v2/organizations/8483e4f1-d3a3-43e2-ab8c-b05ea40ef8db",
    "shared_organizations_url": "/v2/private_domains/b98aeca1-22b9-49f9-8428-3ace9ea2ba11/shared_organizations"
  }
}`

const ListBuildpacksPayload = `{
  "total_results": 3,
  "total_pages": 1,
  "prev_url": null,
  "next_url": "/v2/buildpacksPage2",
  "resources": [
    {
      "metadata": {
        "guid": "c92b6f5f-d2a4-413a-b515-647d059723aa",
        "url": "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name_1",
        "position": 1,
        "enabled": true,
        "locked": false,
        "filename": "name-1616"
      }
    },
    {
      "metadata": {
        "guid": "4de2ac22-ef36-4d62-9698-5f2b426748a9",
        "url": "/v2/buildpacks/4de2ac22-ef36-4d62-9698-5f2b426748a9",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name_2",
        "position": 2,
        "enabled": true,
        "locked": false,
        "filename": "name-1617"
      }
    },
    {
      "metadata": {
        "guid": "79f16936-56f1-41d5-a4c4-f0e9a8877791",
        "url": "/v2/buildpacks/79f16936-56f1-41d5-a4c4-f0e9a8877791",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name_3",
        "position": 3,
        "enabled": true,
        "locked": false,
        "filename": "name-1618"
      }
    }
  ]
}`

const ListBuildpacksPayload2 = `{
  "total_results": 3,
  "total_pages": 1,
  "prev_url": "/v2/buildpacks",
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "c92b6f5f-d2a4-413a-b515-647d059723aa",
        "url": "/v2/buildpacks/c92b6f5f-d2a4-413a-b515-647d059723aa",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name_1",
        "position": 1,
        "enabled": true,
        "locked": false,
        "filename": "name-1616"
      }
    },
    {
      "metadata": {
        "guid": "4de2ac22-ef36-4d62-9698-5f2b426748a9",
        "url": "/v2/buildpacks/4de2ac22-ef36-4d62-9698-5f2b426748a9",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name_2",
        "position": 2,
        "enabled": true,
        "locked": false,
        "filename": "name-1617"
      }
    },
    {
      "metadata": {
        "guid": "79f16936-56f1-41d5-a4c4-f0e9a8877791",
        "url": "/v2/buildpacks/79f16936-56f1-41d5-a4c4-f0e9a8877791",
        "created_at": "2016-06-08T16:41:31Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "name_3",
        "position": 3,
        "enabled": true,
        "locked": false,
        "filename": "name-1618"
      }
    }
  ]
}`

const listUsersPayload = `{
   "total_results": 8,
   "total_pages": 2,
   "prev_url": null,
   "next_url": "/v2/usersPage2",
   "resources": [
      {
         "metadata": {
            "guid": "ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac",
            "url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac",
            "created_at": "2017-01-13T10:50:21Z",
            "updated_at": "2017-01-27T12:20:08Z"
         },
         "entity": {
            "admin": false,
            "active": false,
            "default_space_guid": null,
            "username": "testUser1",
            "spaces_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/spaces",
            "organizations_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/organizations",
            "managed_organizations_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/managed_organizations",
            "billing_managed_organizations_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/billing_managed_organizations",
            "audited_organizations_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/audited_organizations",
            "managed_spaces_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/managed_spaces",
            "audited_spaces_url": "/v2/users/ccec6d06-5f71-48a0-a4c5-c91a1d9f2fac/audited_spaces"
         }
      },
      {
         "metadata": {
            "guid": "f97f5699-c920-4633-aa23-bd70f3db0808",
            "url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808",
            "created_at": "2017-01-17T15:08:45Z",
            "updated_at": "2017-01-27T12:23:17Z"
         },
         "entity": {
            "admin": false,
            "active": true,
            "default_space_guid": null,
            "username": "testUser2",
            "spaces_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/spaces",
            "organizations_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/organizations",
            "managed_organizations_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/managed_organizations",
            "billing_managed_organizations_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/billing_managed_organizations",
            "audited_organizations_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/audited_organizations",
            "managed_spaces_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/managed_spaces",
            "audited_spaces_url": "/v2/users/f97f5699-c920-4633-aa23-bd70f3db0808/audited_spaces"
         }
      }
   ]
}`

const listUsersPayloadPage2 = `{
   "total_results": 8,
   "total_pages": 2,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "cadd6389-fcf6-4928-84f0-6153556bf693",
            "url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693",
            "created_at": "2017-01-04T06:27:51Z",
            "updated_at": "2017-01-27T12:21:19Z"
         },
         "entity": {
            "admin": false,
            "active": false,
            "default_space_guid": null,
            "username": "testUser3",
            "spaces_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/spaces",
            "organizations_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/organizations",
            "managed_organizations_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/managed_organizations",
            "billing_managed_organizations_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/billing_managed_organizations",
            "audited_organizations_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/audited_organizations",
            "managed_spaces_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/managed_spaces",
            "audited_spaces_url": "/v2/users/cadd6389-fcf6-4928-84f0-6153556bf693/audited_spaces"
         }
      },
      {
         "metadata": {
            "guid": "79c854b0-c12a-41b7-8d3c-fdd6e116e385",
            "url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385",
            "created_at": "2017-01-05T14:50:42Z",
            "updated_at": "2017-01-27T12:23:17Z"
         },
         "entity": {
            "admin": false,
            "active": false,
            "default_space_guid": null,
            "username": "testUser4",
            "spaces_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/spaces",
            "organizations_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/organizations",
            "managed_organizations_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/managed_organizations",
            "billing_managed_organizations_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/billing_managed_organizations",
            "audited_organizations_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/audited_organizations",
            "managed_spaces_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/managed_spaces",
            "audited_spaces_url": "/v2/users/79c854b0-c12a-41b7-8d3c-fdd6e116e385/audited_spaces"
         }
      }
   ]
}`

const listUserSpacesPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "9881c79e-d269-4a53-9d77-cb21b745356e",
        "url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e",
        "created_at": "2016-06-08T16:41:37Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "dev",
        "organization_guid": "6a2a2d18-7620-43cf-a332-353824b431b2",
        "space_quota_definition_guid": null,
        "allow_ssh": true,
        "organization_url": "/v2/organizations/6a2a2d18-7620-43cf-a332-353824b431b2",
        "developers_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/developers",
        "managers_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/managers",
        "auditors_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/auditors",
        "apps_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/apps",
        "routes_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/routes",
        "domains_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/domains",
        "service_instances_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/service_instances",
        "app_events_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/app_events",
        "events_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/events",
        "security_groups_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/security_groups",
        "staging_security_groups_url": "/v2/spaces/9881c79e-d269-4a53-9d77-cb21b745356e/staging_security_groups"
      }
    }
  ]
}
`

const listUserOrgsPayload = `{
  "total_results": 1,
  "total_pages": 1,
  "prev_url": null,
  "next_url": null,
  "resources": [
    {
      "metadata": {
        "guid": "9881c79e-d269-4a53-9d77-cb21b745356e",
        "url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e",
        "created_at": "2016-06-08T16:41:37Z",
        "updated_at": "2016-06-08T16:41:26Z"
      },
      "entity": {
        "name": "dev",
        "billing_enabled": false,
        "quota_definition_guid": "6a2a2d18-7620-43cf-a332-353824b431b2",
        "status": "active",
        "quota_definition_url": "/v2/quota_definitions/6a2a2d18-7620-43cf-a332-353824b431b2",
        "spaces_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/spaces",
        "domains_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/domains",
        "private_domains_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/private_domains",
        "users_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/users",
        "managers_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/managers",
        "billing_managers_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/billing_managers",
        "auditors_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/auditors",
        "app_events_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/app_events",
        "space_quota_definitions_url": "/v2/organizations/9881c79e-d269-4a53-9d77-cb21b745356e/space_quota_definitions"
      }
    }
  ]
}
`

const createUserPayload = `{
  "metadata": {
    "guid": "guid-cb24b36d-4656-468e-a50d-b53113ac6177",
    "url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177",
    "created_at": "2016-06-08T16:41:37Z",
    "updated_at": "2016-06-08T16:41:26Z"
  },
  "entity": {
    "admin": false,
    "active": false,
    "default_space_guid": null,
    "spaces_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/spaces",
    "organizations_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/organizations",
    "managed_organizations_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/managed_organizations",
    "billing_managed_organizations_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/billing_managed_organizations",
    "audited_organizations_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/audited_organizations",
    "managed_spaces_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/managed_spaces",
    "audited_spaces_url": "/v2/users/guid-cb24b36d-4656-468e-a50d-b53113ac6177/audited_spaces"
  }
}`

const createIsolationSegmentPayload = `{
   "guid": "323f211e-fea3-4161-9bd1-615392327913",
   "name": "TheKittenIsTheShark",
   "created_at": "2016-10-19T20:25:04Z",
   "updated_at": "2016-11-08T16:41:26Z",
   "links": {
      "self": {
         "href": "https://api.example.org/v3/isolation_segments/323f211e-fea3-4161-9bd1-615392327913"
      },
      "spaces": {
         "href": "https://api.example.org/v3/isolation_segments/323f211e-fea3-4161-9bd1-615392327913/relationships/spaces"
      },
      "organizations": {
         "href": "https://api.example.org/v3/isolation_segments/323f211e-fea3-4161-9bd1-615392327913/relationships/organizations"
      }
   }
}`

const listIsolationSegmentsPayload = `{
   "pagination": {
      "total_results": 2,
      "total_pages": 1,
      "first": {
         "href": "https://api.example.org/v3/isolation_segments?page=1&per_page=50"
      },
      "last": {
         "href": "https://api.example.org/v3/isolation_segments?page=1&per_page=50"
      },
      "next": null,
      "previous": null
   },
   "resources": [
      {
         "guid": "033b4c58-12bb-499a-b05d-4b6fc9e2993b",
         "name": "shared",
         "created_at": "2017-04-02T11:22:04Z",
         "updated_at": "2017-04-02T11:22:04Z",
         "links": {
            "self": {
               "href": "https://api.example.org/v3/isolation_segments/033b4c58-12bb-499a-b05d-4b6fc9e2993b"
            },
            "organizations": {
               "href": "https://api.example.org/v3/isolation_segments/033b4c58-12bb-499a-b05d-4b6fc9e2993b/organizations"
            },
            "spaces": {
               "href": "https://api.example.org/v3/isolation_segments/033b4c58-12bb-499a-b05d-4b6fc9e2993b/relationships/spaces"
            }
         }
      },
      {
         "guid": "23d0baf4-9d3c-44d8-b2dc-1767bcdad1e0",
         "name": "my_segment",
         "created_at": "2017-04-07T11:20:16Z",
         "updated_at": "2017-04-07T11:20:16Z",
         "links": {
            "self": {
               "href": "https://api.example.org/v3/isolation_segments/23d0baf4-9d3c-44d8-b2dc-1767bcdad1e0"
            },
            "organizations": {
               "href": "https://api.example.org/v3/isolation_segments/23d0baf4-9d3c-44d8-b2dc-1767bcdad1e0/organizations"
            },
            "spaces": {
               "href": "https://api.example.org/v3/isolation_segments/23d0baf4-9d3c-44d8-b2dc-1767bcdad1e0/relationships/spaces"
            }
         }
      }
   ]
}`

const addOrgToIsolationSegmentPayload = `{
   "guid": "033b4c58-12bb-499a-b05d-4b6fc9e2993b",
   "name": "shared",
   "created_at": "2016-10-19T20:25:04Z",
   "updated_at": "2016-11-08T16:41:26Z",
   "links": {
      "self": {
         "href": "https://api.example.org/v3/isolation_segments/033b4c58-12bb-499a-b05d-4b6fc9e2993b"
      },
      "spaces": {
         "href": "https://api.example.org/v3/isolation_segments/033b4c58-12bb-499a-b05d-4b6fc9e2993b/relationships/spaces"
      },
      "organizations": {
         "href": "https://api.example.org/v3/isolation_segments/033b4c58-12bb-499a-b05d-4b6fc9e2993b/relationships/organizations"
      }
   }
}`

const listServiceKeysPayload = `{
   "total_results": 2,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "3b933598-64ed-4613-a0f5-b7e8c0379368",
            "url": "/v2/service_keys/3b933598-64ed-4613-a0f5-b7e8c0379368",
            "created_at": "2016-08-01T15:17:35Z",
            "updated_at": "2016-08-01T15:17:35Z"
         },
         "entity": {
            "name": "RedisMonitoringKey",
            "service_instance_guid": "ad98f310-a3a0-47aa-9116-f8295d41a9b2",
            "credentials": {
               "host": "10.10.10.10",
               "password": "some-password",
               "port": 12345
            },
            "service_instance_url": "/v2/service_instances/ad98f310-a3a0-47aa-9116-f8295d41a9b2"
         }
      },
      {
         "metadata": {
            "guid": "8be3911b-c621-4467-8866-f8b924aaee57",
            "url": "/v2/service_keys/8be3911b-c621-4467-8866-f8b924aaee57",
            "created_at": "2017-05-16T12:14:46Z",
            "updated_at": "2017-05-16T12:14:46Z"
         },
         "entity": {
            "name": "test01_key",
            "service_instance_guid": "ecf26687-e176-4784-b181-b3c942fecb62",
            "credentials": {
               "jms": "nhp://100.100.100.100:9008",
               "js_uri": "http://100.100.100.100:9008",
               "amqp": "amqp://100.100.100.100:9008",
               "nhp": "nhp://100.100.100.100:9009",
               "mqtt": "tcp://100.100.100.100:9008",
               "name": "fcf26687-e176-4784-b181-b3c942fecb62",
               "nsp": "nsp://100.100.100.100:9008",
               "userid": "cfu-9be3911b-c621-4467-8866-f8b924aaee57",
               "uri": "nhp://100.100.100.100:9008",
               "uriInfos": [
                  {
                     "host": "100.100.100.100",
                     "port": 9008
                  }
               ]
            },
            "service_instance_url": "/v2/service_instances/fcf26687-e176-4784-b181-b3c942fecb62"
        }
    }
  ]
}`

const getServiceKeyPayload = `{
   "total_results": 1,
   "total_pages": 1,
   "prev_url": null,
   "next_url": null,
   "resources": [
      {
         "metadata": {
            "guid": "8be3911b-c621-4467-8866-f8b924aaee57",
            "url": "/v2/service_keys/8be3911b-c621-4467-8866-f8b924aaee57",
            "created_at": "2017-05-16T12:14:46Z",
            "updated_at": "2017-05-16T12:14:46Z"
         },
         "entity": {
            "name": "test01_key",
            "service_instance_guid": "ecf26687-e176-4784-b181-b3c942fecb62",
            "credentials": {
               "jms": "nhp://100.100.100.100:9008",
               "js_uri": "http://100.100.100.100:9008",
               "amqp": "amqp://100.100.100.100:9008",
               "nhp": "nhp://100.100.100.100:9009",
               "mqtt": "tcp://100.100.100.100:9008",
               "name": "fcf26687-e176-4784-b181-b3c942fecb62",
               "nsp": "nsp://100.100.100.100:9008",
               "userid": "cfu-9be3911b-c621-4467-8866-f8b924aaee57",
               "uri": "nhp://100.100.100.100:9008",
               "uriInfos": [
                  {
                     "host": "100.100.100.100",
                     "port": 9008
                  }
               ]
            },
            "service_instance_url": "/v2/service_instances/fcf26687-e176-4784-b181-b3c942fecb62"
        }
    }
  ]
}`
