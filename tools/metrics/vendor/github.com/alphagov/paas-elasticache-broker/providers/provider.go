package providers

import (
	"context"
	"time"
)

// ServiceState is the state of a service instance
type ServiceState string

// Service states
const (
	Creating     ServiceState = "creating"
	Available    ServiceState = "available"
	Modifying    ServiceState = "modifying"
	Deleting     ServiceState = "deleting"
	CreateFailed ServiceState = "create-failed"
	Snapshotting ServiceState = "snapshotting"
	NonExisting  ServiceState = "non-existing"
)

type ProvisionParameters struct {
	InstanceType               string
	CacheParameterGroupName    string
	SecurityGroupIds           []string
	CacheSubnetGroupName       string
	PreferredMaintenanceWindow string
	ReplicasPerNodeGroup       int64
	ShardCount                 int64
	SnapshotRetentionLimit     int64
	RestoreFromSnapshot        *string
	AutomaticFailoverEnabled   bool
	Description                string
	Parameters                 map[string]string
	Tags                       map[string]string
}

type DeprovisionParameters struct {
	FinalSnapshotIdentifier string
}

type UpdateParameters struct {
	Parameters map[string]string
}

type SnapshotInfo struct {
	Name       string
	CreateTime time.Time
	Tags       map[string]string
}

// Provider is a general interface to implement the broker's functionality with a specific provider
//
//go:generate counterfeiter -o mocks/provider.go . Provider
type Provider interface {
	Provision(ctx context.Context, instanceID string, params ProvisionParameters) error
	Update(ctx context.Context, instanceID string, params UpdateParameters) error
	Deprovision(ctx context.Context, instanceID string, params DeprovisionParameters) error
	GetState(ctx context.Context, instanceID string) (ServiceState, string, error)
	GenerateCredentials(ctx context.Context, instanceID, bindingID string) (*Credentials, error)
	RevokeCredentials(ctx context.Context, instanceID, bindingID string) error
	DeleteCacheParameterGroup(ctx context.Context, instanceID string) error
	FindSnapshots(ctx context.Context, instanceID string) ([]SnapshotInfo, error)
}

// Credentials are the connection parameters for Redis clients
type Credentials struct {
	Host       string `json:"host"`
	Port       int64  `json:"port"`
	Name       string `json:"name"`
	Password   string `json:"password"`
	URI        string `json:"uri"`
	TLSEnabled bool   `json:"tls_enabled"`
}
