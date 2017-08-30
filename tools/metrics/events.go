package main

import (
	"time"
)

type AppUsageEvent struct {
	Entity struct {
		State                     string `json:"state"`
		PreviousState             string `json:"previous_state,omitempty"`
		MemoryPerInstance         int    `json:"memory_in_mb_per_instance,omitempty"`
		PreviousMemoryPerInstance int    `json:"previous_memory_in_mb_per_instance"`
		InstanceCount             int    `json:"instance_count,omitempty"`
		PreviousInstanceCount     int    `json:"previous_instance_count,omitempty"`
		AppGuid                   string `json:"app_guid,omitempty"`
		AppName                   string `json:"app_name,omitempty"`
		SpaceGuid                 string `json:"space_guid"`
		SpaceName                 string `json:"space_name"`
		OrgGuid                   string `json:"org_guid"`
		BuildpackGuid             string `json:"buildpack_guid"`
		BuildpackName             string `json:"buildpack_name"`
		PackageState              string `json:"package_state"`
		PreviousPackageState      string `json:"previous_package_state"`
		ParentAppGuid             string `json:"parent_app_guid"`
		ParentAppName             string `json:"parent_app_name"`
		ProcessType               string `json:"process_type"`
		TaskName                  string `json:"task_name,omitempty"`
		TaskGuid                  string `json:"task_guid,omitempty"`
	}
	MetaData struct {
		Guid      string    `json:"guid"`
		CreatedAt time.Time `json:"created_at"`
	}
}

type AuditEvent struct {
	Entity struct {
		Type             string                 `json:"type"`
		Actor            string                 `json:"actor"`
		ActorType        string                 `json:"actor_type"`
		ActorName        string                 `json:"actor_name"`
		Actee            string                 `json:"actee"`
		ActeeType        string                 `json:"actee_type"`
		ActeeName        string                 `json:"actee_name"`
		Timestamp        time.Time              `json:"timestamp"`
		Metadata         map[string]interface{} `json:"metadata"`
		SpaceGuid        string                 `json:"space_guid"`
		OrganizationGuid string                 `json:"organization_guid"`
	}
	MetaData struct {
		Guid      string    `json:"guid"`
		CreatedAt time.Time `json:"created_at"`
		UpdatedAt time.Time `json:"updated_at"`
	}
}

type ServiceUsageEvent struct {
	MetaData struct {
		Guid      string    `json:"guid"`
		CreatedAt time.Time `json:"created_at"`
	}
	Entity struct {
		State               string `json:"state"`
		OrgGuid             string `json:"org_guid"`
		SpaceGuid           string `json:"space_guid"`
		SpaceName           string `json:"space_name"`
		ServiceInstanceGuid string `json:"service_instance_guid"`
		ServiceInstanceName string `json:"service_instance_name"`
		ServiceInstanceType string `json:"service_instance_type"`
		ServicePlanGuid     string `json:"service_plan_guid"`
		ServicePlanName     string `json:"service_plan_name"`
		ServiceGuid         string `json:"service_guid"`
		ServiceLabel        string `json:"service_label"`
	}
}
