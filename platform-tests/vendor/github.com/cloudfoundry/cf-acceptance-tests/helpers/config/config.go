package config

import (
	"time"
)

type CatsConfig interface {
	GetIncludeAppSyslogTcp() bool
	GetIncludeApps() bool
	GetIncludeContainerNetworking() bool
	GetIncludeCredhubAssisted() bool
	GetIncludeCredhubNonAssisted() bool
	GetIncludeDetect() bool
	GetIncludeDocker() bool
	GetIncludeInternetDependent() bool
	GetIncludePrivateDockerRegistry() bool
	GetIncludeRouteServices() bool
	GetIncludeRouting() bool
	GetIncludeZipkin() bool
	GetIncludeSSO() bool
	GetIncludeSecurityGroups() bool
	GetIncludeServices() bool
	GetIncludeUserProvidedServices() bool
	GetIncludeServiceDiscovery() bool
	GetIncludeSsh() bool
	GetIncludeTasks() bool
	GetIncludeV3() bool
	GetIncludeDeployments() bool
	GetIncludeIsolationSegments() bool
	GetIncludeRoutingIsolationSegments() bool
	GetIncludeServiceInstanceSharing() bool
	GetIncludeTCPIsolationSegments() bool
	GetIncludeHTTP2Routing() bool
	GetIncludeTCPRouting() bool
	GetIncludeWindows() bool
	GetIncludeVolumeServices() bool
	GetShouldKeepUser() bool
	GetSkipSSLValidation() bool
	GetUseExistingUser() bool

	GetAddExistingUserToExistingSpace() bool
	GetAdminPassword() string
	GetAdminUser() string
	GetAdminOrigin() string
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
	GetUserOrigin() string
	GetExistingClient() string
	GetExistingClientSecret() string
	GetGoBuildpackName() string
	GetHwcBuildpackName() string
	GetIsolationSegmentName() string
	GetIsolationSegmentDomain() string
	GetJavaBuildpackName() string
	GetNamePrefix() string
	GetNginxBuildpackName() string
	GetNodejsBuildpackName() string
	GetPrivateDockerRegistryImage() string
	GetPrivateDockerRegistryUsername() string
	GetPrivateDockerRegistryPassword() string
	GetRBuildpackName() string
	GetRubyBuildpackName() string
	GetUnallocatedIPForSecurityGroup() string
	GetRequireProxiedAppTraffic() bool
	GetDynamicASGsEnabled() bool
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
