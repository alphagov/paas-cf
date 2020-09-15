package config

import (
	"time"
)

type CatsConfig interface {
	GetIncludeApps() bool
	GetIncludeContainerNetworking() bool
	GetIncludeCredhubAssisted() bool
	GetIncludeCredhubNonAssisted() bool
	GetIncludeDetect() bool
	GetIncludeDocker() bool
	GetIncludeInternetDependent() bool
	GetIncludeInternetless() bool
	GetIncludePrivateDockerRegistry() bool
	GetIncludeRouteServices() bool
	GetIncludeRouting() bool
	GetIncludeZipkin() bool
	GetIncludeSSO() bool
	GetIncludeSecurityGroups() bool
	GetIncludeServices() bool
	GetIncludeServiceDiscovery() bool
	GetIncludeSsh() bool
	GetIncludeTasks() bool
	GetIncludeV3() bool
	GetIncludeDeployments() bool
	GetIncludeIsolationSegments() bool
	GetIncludeRoutingIsolationSegments() bool
	GetIncludeServiceInstanceSharing() bool
	GetIncludeTCPRouting() bool
	GetIncludeWindows() bool
	GetIncludeVolumeServices() bool
	GetShouldKeepUser() bool
	GetSkipSSLValidation() bool
	GetUseExistingUser() bool

	GetAddExistingUserToExistingSpace() bool
	GetAdminPassword() string
	GetAdminUser() string
	GetAdminClient() string
	GetAdminClientSecret() string
	GetApiEndpoint() string
	GetAppsDomain() string
	GetArtifactsDirectory() string
	GetBinaryBuildpackName() string
	GetStaticFileBuildpackName() string
	GetConfigurableTestPassword() string
	GetCredHubBrokerClientCredential() string
	GetCredHubBrokerClientSecret() string
	GetCredHubLocation() string
	GetExistingOrganization() string
	GetUseExistingOrganization() bool
	GetExistingSpace() string
	GetUseExistingSpace() bool
	GetExistingUser() string
	GetExistingUserPassword() string
	GetExistingClient() string
	GetExistingClientSecret() string
	GetGoBuildpackName() string
	GetHwcBuildpackName() string
	GetIsolationSegmentName() string
	GetIsolationSegmentDomain() string
	GetJavaBuildpackName() string
	GetNamePrefix() string
	GetNodejsBuildpackName() string
	GetPrivateDockerRegistryImage() string
	GetPrivateDockerRegistryUsername() string
	GetPrivateDockerRegistryPassword() string
	GetRubyBuildpackName() string
	GetUnallocatedIPForSecurityGroup() string
	GetRequireProxiedAppTraffic() bool
	Protocol() string

	GetStacks() []string

	GetUseWindowsTestTask() bool
	GetUseWindowsContextPath() bool
	GetWindowsStack() string

	GetVolumeServiceName() string
	GetVolumeServicePlanName() string
	GetVolumeServiceCreateConfig() string

	GetReporterConfig() reporterConfig

	AsyncServiceOperationTimeoutDuration() time.Duration
	BrokerStartTimeoutDuration() time.Duration
	CfPushTimeoutDuration() time.Duration
	DefaultTimeoutDuration() time.Duration
	DetectTimeoutDuration() time.Duration
	GetScaledTimeout(time.Duration) time.Duration
	LongCurlTimeoutDuration() time.Duration
	SleepTimeoutDuration() time.Duration

	GetPublicDockerAppImage() string

	RunningOnK8s() bool
}

func NewCatsConfig(path string) (CatsConfig, error) {
	return NewConfig(path)
}
