package main

import (
	"time"
)

// UsageEvent can be used interchangeably for `/v2/app_usage_events` and
// `/v2/service_usage_events` results.
type UsageEvent struct {
	Entity   Entity   `json:"entity"`
	MetaData MetaData `json:"metadata"`
}

type Entity struct {
	// Common
	State     string `json:"state"`
	OrgGuid   string `json:"org_guid"`
	SpaceGuid string `json:"space_guid"`
	SpaceName string `json:"space_name"`

	// App
	AppGuid           string `json:"app_guid,omitempty"`
	AppName           string `json:"app_name,omitempty"`
	InstanceCount     int    `json:"instance_count,omitempty"`
	MemoryPerInstance int    `json:"memory_in_mb_per_instance,omitempty"`

	// Service
	ServiceInstanceGuid string `json:"service_instance_guid,omitempty"`
	ServiceInstanceName string `json:"service_instance_name,omitempty"`
	ServiceInstanceType string `json:"service_instance_type,omitempty"`
	ServiceLabel        string `json:"service_label,omitempty"`
	ServicePlanName     string `json:"service_plan_name,omitempty"`
}

type MetaData struct {
	CreatedAt time.Time `json:"created_at"`
}
