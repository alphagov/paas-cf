package config

import (
	"time"
)

type CatsConfig interface {
	GetIncludeApps() bool
	GetIncludeBackendCompatiblity() bool
	GetIncludeCapiExperimental() bool
	GetIncludeCapiNoBridge() bool
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
	GetIncludeServiceDiscovery() bool
	GetIncludeSsh() bool
	GetIncludeTasks() bool
	GetIncludeV3() bool
	GetIncludeIsolationSegments() bool
	GetIncludeRoutingIsolationSegments() bool
	GetIncludeServiceInstanceSharing() bool
	GetIncludeTCPRouting() bool
	GetIncludeWindows() bool
	GetUseLogCache() bool
	GetShouldKeepUser() bool
	GetSkipSSLValidation() bool
	GetUseExistingUser() bool

	GetAdminPassword() string
	GetAdminUser() string
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
	Protocol() string

	GetUseWindowsTestTask() bool
	GetUseWindowsContextPath() bool
	GetWindowsStack() string

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
}

func NewCatsConfig(path string) (CatsConfig, error) {
	return NewConfig(path)
}
