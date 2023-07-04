package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"time"
)

const (
	CredhubAssistedMode    = "assisted"
	CredhubNonAssistedMode = "non-assisted"
)

type config struct {
	ApiEndpoint *string `json:"api"`
	AppsDomain  *string `json:"apps_domain"`
	UseHttp     *bool   `json:"use_http"`

	AdminPassword *string `json:"admin_password"`
	AdminUser     *string `json:"admin_user"`

	ExistingUser         *string `json:"existing_user"`
	ExistingUserPassword *string `json:"existing_user_password"`
	ShouldKeepUser       *bool   `json:"keep_user_at_suite_end"`
	UseExistingUser      *bool   `json:"use_existing_user"`

	UseExistingOrganization *bool   `json:"use_existing_organization"`
	ExistingOrganization    *string `json:"existing_organization"`

	ConfigurableTestPassword *string `json:"test_password"`

	IsolationSegmentName   *string `json:"isolation_segment_name"`
	IsolationSegmentDomain *string `json:"isolation_segment_domain"`

	SkipSSLValidation *bool `json:"skip_ssl_validation"`

	ArtifactsDirectory *string `json:"artifacts_directory"`

	AsyncServiceOperationTimeout *int `json:"async_service_operation_timeout"`
	BrokerStartTimeout           *int `json:"broker_start_timeout"`
	CfPushTimeout                *int `json:"cf_push_timeout"`
	DefaultTimeout               *int `json:"default_timeout"`
	DetectTimeout                *int `json:"detect_timeout"`
	LongCurlTimeout              *int `json:"long_curl_timeout"`
	SleepTimeout                 *int `json:"sleep_timeout"`

	TimeoutScale *float64 `json:"timeout_scale"`

	BinaryBuildpackName     *string `json:"binary_buildpack_name"`
	GoBuildpackName         *string `json:"go_buildpack_name"`
	HwcBuildpackName        *string `json:"hwc_buildpack_name"`
	JavaBuildpackName       *string `json:"java_buildpack_name"`
	NginxBuildpackName      *string `json:"nginx_buildpack_name"`
	NodejsBuildpackName     *string `json:"nodejs_buildpack_name"`
	RBuildpackName          *string `json:"r_buildpack_name"`
	RubyBuildpackName       *string `json:"ruby_buildpack_name"`
	StaticFileBuildpackName *string `json:"staticfile_buildpack_name"`

	VolumeServiceName         *string `json:"volume_service_name"`
	VolumeServicePlanName     *string `json:"volume_service_plan_name"`
	VolumeServiceCreateConfig *string `json:"volume_service_create_config"`

	IncludeAppSyslogTCP             *bool `json:"include_app_syslog_tcp"`
	IncludeApps                     *bool `json:"include_apps"`
	IncludeContainerNetworking      *bool `json:"include_container_networking"`
	IncludeDeployments              *bool `json:"include_deployments"`
	IncludeDetect                   *bool `json:"include_detect"`
	IncludeDocker                   *bool `json:"include_docker"`
	IncludeInternetDependent        *bool `json:"include_internet_dependent"`
	IncludeIsolationSegments        *bool `json:"include_isolation_segments"`
	IncludePrivateDockerRegistry    *bool `json:"include_private_docker_registry"`
	IncludeRouteServices            *bool `json:"include_route_services"`
	IncludeRouting                  *bool `json:"include_routing"`
	IncludeRoutingIsolationSegments *bool `json:"include_routing_isolation_segments"`
	IncludeSSO                      *bool `json:"include_sso"`
	IncludeSecurityGroups           *bool `json:"include_security_groups"`
	IncludeServiceDiscovery         *bool `json:"include_service_discovery"`
	IncludeServiceInstanceSharing   *bool `json:"include_service_instance_sharing"`
	IncludeServices                 *bool `json:"include_services"`
	IncludeUserProvidedServices     *bool `json:"include_user_provided_services"`
	IncludeSsh                      *bool `json:"include_ssh"`
	IncludeTCPIsolationSegments     *bool `json:"include_tcp_isolation_segments"`
	IncludeHTTP2Routing             *bool `json:"include_http2_routing"`
	IncludeTCPRouting               *bool `json:"include_tcp_routing"`
	IncludeTasks                    *bool `json:"include_tasks"`
	IncludeV3                       *bool `json:"include_v3"`
	IncludeVolumeServices           *bool `json:"include_volume_services"`
	IncludeZipkin                   *bool `json:"include_zipkin"`

	CredhubMode         *string `json:"credhub_mode"`
	CredhubLocation     *string `json:"credhub_location"`
	CredhubClientName   *string `json:"credhub_client"`
	CredhubClientSecret *string `json:"credhub_secret"`

	Stacks *[]string `json:"stacks,omitempty"`

	IncludeWindows        *bool `json:"include_windows"`
	UseWindowsTestTask    *bool `json:"use_windows_test_task"`
	UseWindowsContextPath *bool `json:"use_windows_context_path"`

	PrivateDockerRegistryImage    *string `json:"private_docker_registry_image"`
	PrivateDockerRegistryUsername *string `json:"private_docker_registry_username"`
	PrivateDockerRegistryPassword *string `json:"private_docker_registry_password"`
	PublicDockerAppImage          *string `json:"public_docker_app_image"`

	UnallocatedIPForSecurityGroup *string `json:"unallocated_ip_for_security_group"`
	RequireProxiedAppTraffic      *bool   `json:"require_proxied_app_traffic"`

	DynamicASGsEnabled *bool `json:"dynamic_asgs_enabled"`

	NamePrefix *string `json:"name_prefix"`

	ReporterConfig *reporterConfig `json:"reporter_config"`

	Infrastructure *string `json:"infrastructure"`
}

type reporterConfig struct {
	HoneyCombWriteKey string                 `json:"honeycomb_write_key"`
	HoneyCombDataset  string                 `json:"honeycomb_dataset"`
	CustomTags        map[string]interface{} `json:"custom_tags"`
}

var defaults = config{}

func ptrToString(str string) *string {
	return &str
}

func ptrToBool(b bool) *bool {
	return &b
}

func ptrToInt(i int) *int {
	return &i
}

func ptrToFloat(f float64) *float64 {
	return &f
}

func getDefaults() config {
	defaults.IsolationSegmentName = ptrToString("")
	defaults.IsolationSegmentDomain = ptrToString("")

	defaults.BinaryBuildpackName = ptrToString("binary_buildpack")
	defaults.GoBuildpackName = ptrToString("go_buildpack")
	defaults.HwcBuildpackName = ptrToString("hwc_buildpack")
	defaults.JavaBuildpackName = ptrToString("java_buildpack")
	defaults.NginxBuildpackName = ptrToString("nginx_buildpack")
	defaults.NodejsBuildpackName = ptrToString("nodejs_buildpack")
	defaults.RBuildpackName = ptrToString("r_buildpack")
	defaults.RubyBuildpackName = ptrToString("ruby_buildpack")
	defaults.StaticFileBuildpackName = ptrToString("staticfile_buildpack")

	defaults.IncludeAppSyslogTCP = ptrToBool(true)
	defaults.IncludeApps = ptrToBool(true)
	defaults.IncludeDetect = ptrToBool(true)
	defaults.IncludeRouting = ptrToBool(true)
	defaults.IncludeV3 = ptrToBool(true)
	defaults.IncludeDeployments = ptrToBool(false)

	defaults.IncludeContainerNetworking = ptrToBool(false)
	defaults.CredhubMode = ptrToString("")
	defaults.CredhubLocation = ptrToString("https://credhub.service.cf.internal:8844")
	defaults.CredhubClientName = ptrToString("credhub_admin_client")
	defaults.CredhubClientSecret = ptrToString("")
	defaults.IncludeDocker = ptrToBool(false)
	defaults.IncludeInternetDependent = ptrToBool(false)
	defaults.IncludeIsolationSegments = ptrToBool(false)
	defaults.IncludeTCPIsolationSegments = ptrToBool(false)
	defaults.IncludeRoutingIsolationSegments = ptrToBool(false)
	defaults.IncludePrivateDockerRegistry = ptrToBool(false)
	defaults.IncludeRouteServices = ptrToBool(false)
	defaults.IncludeSSO = ptrToBool(false)
	defaults.IncludeSecurityGroups = ptrToBool(false)
	defaults.IncludeServiceDiscovery = ptrToBool(false)
	defaults.IncludeServices = ptrToBool(false)
	defaults.IncludeUserProvidedServices = ptrToBool(false)
	defaults.IncludeSsh = ptrToBool(false)
	defaults.IncludeTasks = ptrToBool(false)
	defaults.IncludeZipkin = ptrToBool(false)
	defaults.IncludeServiceInstanceSharing = ptrToBool(false)
	defaults.IncludeHTTP2Routing = ptrToBool(false)
	defaults.IncludeTCPRouting = ptrToBool(false)
	defaults.IncludeVolumeServices = ptrToBool(false)

	defaults.IncludeWindows = ptrToBool(false)
	defaults.UseWindowsContextPath = ptrToBool(false)
	defaults.UseWindowsTestTask = ptrToBool(false)

	defaults.VolumeServiceName = ptrToString("")
	defaults.VolumeServicePlanName = ptrToString("")
	defaults.VolumeServiceCreateConfig = ptrToString("")

	defaults.ReporterConfig = &reporterConfig{}

	defaults.UseHttp = ptrToBool(false)
	defaults.UseExistingUser = ptrToBool(false)
	defaults.ShouldKeepUser = ptrToBool(false)

	defaults.UseExistingOrganization = ptrToBool(false)
	defaults.ExistingOrganization = ptrToString("")

	defaults.AsyncServiceOperationTimeout = ptrToInt(120)
	defaults.BrokerStartTimeout = ptrToInt(300)
	defaults.CfPushTimeout = ptrToInt(240)
	defaults.DefaultTimeout = ptrToInt(30)
	defaults.DetectTimeout = ptrToInt(300)
	defaults.LongCurlTimeout = ptrToInt(120)
	defaults.SleepTimeout = ptrToInt(30)

	defaults.ConfigurableTestPassword = ptrToString("")

	defaults.TimeoutScale = ptrToFloat(2.0)

	defaults.ArtifactsDirectory = ptrToString(filepath.Join("..", "results"))

	defaults.PrivateDockerRegistryImage = ptrToString("")
	defaults.PrivateDockerRegistryUsername = ptrToString("")
	defaults.PrivateDockerRegistryPassword = ptrToString("")
	defaults.PublicDockerAppImage = ptrToString("cloudfoundry/diego-docker-app:latest")

	defaults.UnallocatedIPForSecurityGroup = ptrToString("10.0.244.255")
	defaults.RequireProxiedAppTraffic = ptrToBool(false)

	defaults.DynamicASGsEnabled = ptrToBool(true)

	defaults.NamePrefix = ptrToString("CATS")

	defaults.Stacks = &[]string{"cflinuxfs4"}

	defaults.Infrastructure = ptrToString("vms")
	return defaults
}

func NewConfig(path string) (*config, error) {
	cfg := getDefaults()
	err := load(path, &cfg)
	return &cfg, err
}

func validateConfig(config *config) error {
	var errs error

	err := validateAdminUser(config)
	if err != nil {
		errs = errors.Join(errs, err)
	}

	err = validateAdminPassword(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateApiEndpoint(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateAppsDomain(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validatePublicDockerAppImage(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validatePrivateDockerRegistry(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateIsolationSegments(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateRoutingIsolationSegments(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateTCPIsolationSegments(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateCredHubSettings(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateWindows(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateStacks(config)
	if err != nil {
		errs = errors.Join(errs, err)

	}

	err = validateVolumeServices(config)
	if err != nil {
		errs = errors.Join(errs, err)
	}

	err = validateTimeoutScale(config)
	if err != nil {
		errs = errors.Join(errs, err)
	}

	if config.UseHttp == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'use_http' must not be null"))
	}
	if config.ShouldKeepUser == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'keep_user_at_suite_end' must not be null"))
	}
	if config.UseExistingUser == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'use_existing_user' must not be null"))
	}
	if config.ConfigurableTestPassword == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'test_password' must not be null"))
	}
	if config.IsolationSegmentName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'isolation_segment_name' must not be null"))
	}
	if config.IsolationSegmentDomain == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'isolation_segment_domain' must not be null"))
	}
	if config.SkipSSLValidation == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'skip_ssl_validation' must not be null"))
	}
	if config.ArtifactsDirectory == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'artifacts_directory' must not be null"))
	}
	if config.AsyncServiceOperationTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'async_service_operation_timeout' must not be null"))
	}
	if config.BrokerStartTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'broker_start_timeout' must not be null"))
	}
	if config.CfPushTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'cf_push_timeout' must not be null"))
	}
	if config.DefaultTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'default_timeout' must not be null"))
	}
	if config.DetectTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'detect_timeout' must not be null"))
	}
	if config.LongCurlTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'long_curl_timeout' must not be null"))
	}
	if config.SleepTimeout == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'sleep_timeout' must not be null"))
	}
	if config.BinaryBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'binary_buildpack_name' must not be null"))
	}
	if config.GoBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'go_buildpack_name' must not be null"))
	}
	if config.HwcBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'hwc_buildpack_name' must not be null"))
	}
	if config.JavaBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'java_buildpack_name' must not be null"))
	}
	if config.NginxBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'nginx_buildpack_name' must not be null"))
	}
	if config.NodejsBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'nodejs_buildpack_name' must not be null"))
	}
	if config.RBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'r_buildpack_name' must not be null"))
	}
	if config.RubyBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'ruby_buildpack_name' must not be null"))
	}
	if config.StaticFileBuildpackName == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'staticfile_buildpack_name' must not be null"))
	}
	if config.IncludeAppSyslogTCP == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_app_syslog_tcp' must not be null"))
	}
	if config.IncludeApps == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_apps' must not be null"))
	}
	if config.IncludeContainerNetworking == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_container_networking' must not be null"))
	}
	if config.IncludeDetect == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_detect' must not be null"))
	}
	if config.IncludeDocker == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_docker' must not be null"))
	}
	if config.IncludeInternetDependent == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_internet_dependent' must not be null"))
	}
	if config.IncludePrivateDockerRegistry == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_private_docker_registry' must not be null"))
	}
	if config.IncludeRouteServices == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_route_services' must not be null"))
	}
	if config.IncludeRouting == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_routing' must not be null"))
	}
	if config.IncludeSSO == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_sso' must not be null"))
	}
	if config.IncludeSecurityGroups == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_security_groups' must not be null"))
	}
	if config.IncludeServiceDiscovery == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_service_discovery' must not be null"))
	}
	if config.IncludeServices == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_services' must not be null"))
	}
	if config.IncludeUserProvidedServices == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_user_provided_services' must not be null"))
	}
	if config.IncludeServiceInstanceSharing == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_service_instance_sharing' must not be null"))
	}
	if config.IncludeSsh == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_ssh' must not be null"))
	}
	if config.IncludeTasks == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_tasks' must not be null"))
	}
	if config.IncludeHTTP2Routing == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_http2_routing' must not be null"))
	}
	if config.IncludeTCPRouting == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_tcp_routing' must not be null"))
	}
	if config.IncludeV3 == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_v3' must not be null"))
	}
	if config.IncludeZipkin == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_zipkin' must not be null"))
	}
	if config.IncludeIsolationSegments == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_isolation_segments' must not be null"))
	}
	if config.IncludeTCPIsolationSegments == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'include_isolation_segments' must not be null"))
	}
	if config.PrivateDockerRegistryImage == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'private_docker_registry_image' must not be null"))
	}
	if config.PrivateDockerRegistryUsername == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'private_docker_registry_username' must not be null"))
	}
	if config.PrivateDockerRegistryPassword == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'private_docker_registry_password' must not be null"))
	}
	if config.NamePrefix == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'name_prefix' must not be null"))
	}
	if config.Infrastructure == nil {
		errs = errors.Join(errs, fmt.Errorf("* 'infrastructure' must not be null"))
	}

	return errs
}

func validateApiEndpoint(config *config) error {
	if config.ApiEndpoint == nil {
		return fmt.Errorf("* 'api' must not be null")
	}

	if config.GetApiEndpoint() == "" {
		return fmt.Errorf("* Invalid configuration: 'api' must be a valid Cloud Controller endpoint but was blank")
	}

	// Use URL parse to check endpoint, but we do not want users to provide a scheme/protocol
	u, err := url.Parse(config.GetApiEndpoint())
	if err != nil {
		return fmt.Errorf("* Invalid configuration: 'api' must be a valid domain but was set to '%s'", config.GetApiEndpoint())
	}
	if u.Scheme != "" {
		return fmt.Errorf("* Invalid configuration: 'api' must not contain a scheme/protocol but was set to '%s' in '%s'", u.Scheme, config.GetApiEndpoint())
	}

	host := u.Host
	if host == "" {
		// url.Parse misunderstood our convention and treated the hostname as a URL path
		host = u.Path
	}

	if _, err = net.LookupHost(host); err != nil {
		return fmt.Errorf("* Invalid configuration for 'api' <%s>: %s", config.GetApiEndpoint(), err)
	}

	return nil
}

func validateAppsDomain(config *config) error {
	if config.AppsDomain == nil {
		return fmt.Errorf("* 'apps_domain' must not be null")
	}

	madeUpAppHostname := "made-up-app-host-name." + config.GetAppsDomain()
	u, err := url.Parse(madeUpAppHostname)
	if err != nil {
		return fmt.Errorf("* Invalid configuration: 'apps_domain' must be a valid URL but was set to '%s'", config.GetAppsDomain())
	}

	host := u.Host
	if host == "" {
		// url.Parse misunderstood our convention and treated the hostname as a URL path
		host = u.Path
	}

	if _, err = net.LookupHost(madeUpAppHostname); err != nil {
		return fmt.Errorf("* Invalid configuration for 'apps_domain' <%s>: %s", config.GetAppsDomain(), err)
	}

	return nil
}

func validateAdminUser(config *config) error {
	if config.AdminUser == nil {
		return fmt.Errorf("* 'admin_user' must not be null")
	}

	if config.GetAdminUser() == "" {
		return fmt.Errorf("* Invalid configuration: 'admin_user' must be provided")
	}

	return nil
}

func validateAdminPassword(config *config) error {
	if config.AdminPassword == nil {
		return fmt.Errorf("* 'admin_password' must not be null")
	}

	if config.GetAdminPassword() == "" {
		return fmt.Errorf("* Invalid configuration: 'admin_password' must be provided")
	}

	return nil
}

func validatePublicDockerAppImage(config *config) error {
	if config.PublicDockerAppImage == nil {
		return fmt.Errorf("* 'public_docker_app_image' must not be null")
	}
	if config.GetPublicDockerAppImage() == "" {
		return fmt.Errorf("* Invalid configuration: 'public_docker_app_image' must be set to a valid image source")
	}
	return nil
}

func validatePrivateDockerRegistry(config *config) error {
	if config.IncludePrivateDockerRegistry == nil {
		return fmt.Errorf("* 'include_private_docker_registry' must not be null")
	}
	if config.PrivateDockerRegistryImage == nil {
		return fmt.Errorf("* 'private_docker_registry_image' must not be null")
	}
	if config.PrivateDockerRegistryUsername == nil {
		return fmt.Errorf("* 'private_docker_registry_username' must not be null")
	}
	if config.PrivateDockerRegistryPassword == nil {
		return fmt.Errorf("* 'private_docker_registry_password' must not be null")
	}

	if !config.GetIncludePrivateDockerRegistry() {
		return nil
	}

	if config.GetPrivateDockerRegistryImage() == "" {
		return fmt.Errorf("* Invalid configuration: 'private_docker_registry_image' must be provided if 'include_private_docker_registry' is true")
	}
	if config.GetPrivateDockerRegistryUsername() == "" {
		return fmt.Errorf("* Invalid configuration: 'private_docker_registry_username' must be provided if 'include_private_docker_registry' is true")
	}
	if config.GetPrivateDockerRegistryPassword() == "" {
		return fmt.Errorf("* Invalid configuration: 'private_docker_registry_password' must be provided if 'include_private_docker_registry' is true")
	}

	return nil
}

func validateIsolationSegments(config *config) error {
	if config.IncludeIsolationSegments == nil {
		return fmt.Errorf("* 'include_isolation_segments' must not be null")
	}
	if config.IsolationSegmentName == nil {
		return fmt.Errorf("* 'isolation_segment_name' must not be null")
	}

	if !config.GetIncludeIsolationSegments() {
		return nil
	}

	if config.GetIsolationSegmentName() == "" {
		return fmt.Errorf("* Invalid configuration: 'isolation_segment_name' must be provided if 'include_isolation_segments' is true")
	}
	return nil
}

func validateRoutingIsolationSegments(config *config) error {
	if config.IncludeRoutingIsolationSegments == nil {
		return fmt.Errorf("* 'include_routing_isolation_segments' must not be null")
	}
	if config.IsolationSegmentName == nil {
		return fmt.Errorf("* 'isolation_segment_name' must not be null")
	}
	if config.IsolationSegmentDomain == nil {
		return fmt.Errorf("* 'isolation_segment_domain' must not be null")
	}

	if !config.GetIncludeRoutingIsolationSegments() {
		return nil
	}

	if config.GetIsolationSegmentName() == "" {
		return fmt.Errorf("* Invalid configuration: 'isolation_segment_name' must be provided if 'include_routing_isolation_segments' is true")
	}
	if config.GetIsolationSegmentDomain() == "" {
		return fmt.Errorf("* Invalid configuration: 'isolation_segment_domain' must be provided if 'include_routing_isolation_segments' is true")
	}
	return nil
}

func validateTCPIsolationSegments(config *config) error {
	if config.IncludeTCPIsolationSegments == nil {
		return fmt.Errorf("* 'include_tcp_isolation_segments' must not be null")
	}
	if config.IsolationSegmentName == nil {
		return fmt.Errorf("* 'isolation_segment_name' must not be null")
	}

	if !config.GetIncludeTCPIsolationSegments() {
		return nil
	}

	if !config.GetIncludeIsolationSegments() {
		return fmt.Errorf("* Invalid configuration: 'include_isolation_segments' must be set if 'include_tcp_isolation_segments' is true")
	}
	if config.GetIsolationSegmentName() == "" {
		return fmt.Errorf("* Invalid configuration: 'isolation_segment_name' must be provided if 'include_tcp_isolation_segments' is true")
	}
	return nil
}

func validateCredHubSettings(config *config) error {
	if config.CredhubMode == nil {
		return fmt.Errorf("* 'credhub_mode' must not be null")
	}

	if config.GetIncludeCredhubAssisted() || config.GetIncludeCredhubNonAssisted() {
		if config.GetCredHubBrokerClientCredential() == "" || config.GetCredHubBrokerClientSecret() == "" {
			return fmt.Errorf("* 'credhub_client' and 'credhub_secret' must not be null")
		}
	}

	return nil
}

func validateVolumeServices(config *config) error {
	if config.IncludeVolumeServices == nil {
		return nil
	}

	if !config.GetIncludeVolumeServices() {
		return nil
	}

	if config.GetVolumeServiceName() == "" {
		return fmt.Errorf("* Invalid configuration: 'volume_service_name' must be provided if 'include_volume_services' is true")
	}
	if config.GetVolumeServicePlanName() == "" {
		return fmt.Errorf("* Invalid configuration: 'volume_service_plan_name' must be provided if 'include_volume_services' is true")
	}

	return nil
}

func validateWindows(config *config) error {
	if config.IncludeWindows == nil {
		return fmt.Errorf("* 'include_windows' must not be null")
	}

	if !config.GetIncludeWindows() {
		return nil
	}

	return nil
}

func validateStacks(config *config) error {
	if config.Stacks == nil {
		return fmt.Errorf("* 'stacks' must not be null")
	}

	for _, stack := range config.GetStacks() {
		if stack != "cflinuxfs3" && stack != "cflinuxfs4" {
			return fmt.Errorf("* Invalid configuration: unknown stack '%s'. Only 'cflinuxfs3' and 'cflinuxfs4' is supported for the 'stacks' property", stack)
		}
	}

	return nil
}

func validateTimeoutScale(config *config) error {
	if config.TimeoutScale == nil {
		return fmt.Errorf("* 'timeout_scale' must not be null")
	}

	if *config.TimeoutScale <= 0 {
		return fmt.Errorf("* 'timeout_scale' must be greater than zero")
	}

	return nil
}

func load(path string, config *config) error {
	err := loadConfigFromPath(path, config)
	if err != nil {
		return fmt.Errorf("* Failed to unmarshal: %w", err)
	}

	return validateConfig(config)
}

func loadConfigFromPath(path string, config interface{}) error {
	configFile, err := os.Open(path)
	if err != nil {
		return err
	}
	defer configFile.Close()

	decoder := json.NewDecoder(configFile)
	return decoder.Decode(config)
}

func (c config) GetScaledTimeout(timeout time.Duration) time.Duration {
	return time.Duration(float64(timeout) * *c.TimeoutScale)
}

func (c *config) DefaultTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.DefaultTimeout) * time.Second)
}

func (c *config) LongCurlTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.LongCurlTimeout) * time.Second)
}

func (c *config) SleepTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.SleepTimeout) * time.Second)
}

func (c *config) DetectTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.DetectTimeout) * time.Second)
}

func (c *config) CfPushTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.CfPushTimeout) * time.Second)
}

func (c *config) BrokerStartTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.BrokerStartTimeout) * time.Second)
}

func (c *config) AsyncServiceOperationTimeoutDuration() time.Duration {
	return c.GetScaledTimeout(time.Duration(*c.AsyncServiceOperationTimeout) * time.Second)
}

func (c *config) Protocol() string {
	if *c.UseHttp {
		return "http://"
	} else {
		return "https://"
	}
}

func (c *config) GetAppsDomain() string {
	return *c.AppsDomain
}

func (c *config) GetSkipSSLValidation() bool {
	return *c.SkipSSLValidation
}

func (c *config) GetArtifactsDirectory() string {
	return *c.ArtifactsDirectory
}

func (c *config) GetIsolationSegmentName() string {
	return *c.IsolationSegmentName
}

func (c *config) GetIsolationSegmentDomain() string {
	return *c.IsolationSegmentDomain
}

func (c *config) GetNamePrefix() string {
	return *c.NamePrefix
}

func (c *config) GetExistingOrganization() string {
	return *c.ExistingOrganization
}

func (c *config) GetUseExistingOrganization() bool {
	return *c.UseExistingOrganization
}

func (c *config) GetExistingSpace() string {
	return ""
}

func (c *config) GetUseExistingSpace() bool {
	return false
}

func (c *config) GetUseExistingUser() bool {
	return *c.UseExistingUser
}

func (c *config) GetExistingUser() string {
	return *c.ExistingUser
}

func (c *config) GetExistingUserPassword() string {
	return *c.ExistingUserPassword
}

func (c *config) GetUserOrigin() string {
	return ""
}

func (c *config) GetConfigurableTestPassword() string {
	return *c.ConfigurableTestPassword
}

func (c *config) GetShouldKeepUser() bool {
	return *c.ShouldKeepUser
}

func (c *config) GetAddExistingUserToExistingSpace() bool {
	return false
}

func (c *config) GetAdminUser() string {
	return *c.AdminUser
}

func (c *config) GetAdminPassword() string {
	return *c.AdminPassword
}

func (c *config) GetAdminOrigin() string {
	return ""
}

func (c *config) GetApiEndpoint() string {
	return *c.ApiEndpoint
}

func (c *config) GetIncludeSsh() bool {
	return *c.IncludeSsh
}

func (c *config) GetIncludeAppSyslogTcp() bool {
	return *c.IncludeAppSyslogTCP
}

func (c *config) GetIncludeApps() bool {
	return *c.IncludeApps
}

func (c *config) GetIncludeContainerNetworking() bool {
	return *c.IncludeContainerNetworking
}

func (c *config) GetIncludeDetect() bool {
	return *c.IncludeDetect
}

func (c *config) GetIncludeDocker() bool {
	return *c.IncludeDocker
}

func (c *config) GetIncludeInternetDependent() bool {
	return *c.IncludeInternetDependent
}

func (c *config) GetIncludeRouteServices() bool {
	return *c.IncludeRouteServices
}

func (c *config) GetIncludeRouting() bool {
	return *c.IncludeRouting
}

func (c *config) GetIncludeZipkin() bool {
	return *c.IncludeZipkin
}

func (c *config) GetIncludeTasks() bool {
	return *c.IncludeTasks
}

func (c *config) GetIncludePrivateDockerRegistry() bool {
	return *c.IncludePrivateDockerRegistry
}

func (c *config) GetIncludeSecurityGroups() bool {
	return *c.IncludeSecurityGroups
}

func (c *config) GetDynamicASGsEnabled() bool {
	return *c.DynamicASGsEnabled
}
func (c *config) GetIncludeServices() bool {
	return *c.IncludeServices
}

func (c *config) GetIncludeUserProvidedServices() bool {
	return *c.IncludeUserProvidedServices
}

func (c *config) GetIncludeSSO() bool {
	return *c.IncludeSSO
}

func (c *config) GetIncludeHTTP2Routing() bool {
	return *c.IncludeHTTP2Routing
}

func (c *config) GetIncludeTCPRouting() bool {
	return *c.IncludeTCPRouting
}

func (c *config) GetIncludeV3() bool {
	return *c.IncludeV3
}

func (c *config) GetIncludeDeployments() bool {
	return *c.IncludeDeployments
}

func (c *config) GetIncludeIsolationSegments() bool {
	return *c.IncludeIsolationSegments
}

func (c *config) GetIncludeTCPIsolationSegments() bool {
	return *c.IncludeTCPIsolationSegments
}

func (c *config) GetIncludeRoutingIsolationSegments() bool {
	return *c.IncludeRoutingIsolationSegments
}

func (c *config) GetIncludeCredhubAssisted() bool {
	return *c.CredhubMode == CredhubAssistedMode
}

func (c *config) GetIncludeCredhubNonAssisted() bool {
	return *c.CredhubMode == CredhubNonAssistedMode
}

func (c *config) GetCredHubBrokerClientCredential() string {
	return *c.CredhubClientName
}

func (c *config) GetCredHubBrokerClientSecret() string {
	return *c.CredhubClientSecret
}

func (c *config) GetCredHubLocation() string {
	return *c.CredhubLocation
}

func (c *config) GetIncludeServiceInstanceSharing() bool {
	return *c.IncludeServiceInstanceSharing
}

func (c *config) GetIncludeWindows() bool {
	return *c.IncludeWindows
}

func (c *config) GetIncludeServiceDiscovery() bool {
	return *c.IncludeServiceDiscovery
}

func (c *config) GetIncludeVolumeServices() bool {
	return *c.IncludeVolumeServices
}

func (c *config) GetRBuildpackName() string {
	return *c.RBuildpackName
}

func (c *config) GetRubyBuildpackName() string {
	return *c.RubyBuildpackName
}

func (c *config) GetGoBuildpackName() string {
	return *c.GoBuildpackName
}

func (c *config) GetHwcBuildpackName() string {
	return *c.HwcBuildpackName
}

func (c *config) GetJavaBuildpackName() string {
	return *c.JavaBuildpackName
}

func (c *config) GetNginxBuildpackName() string {
	return *c.NginxBuildpackName
}

func (c *config) GetNodejsBuildpackName() string {
	return *c.NodejsBuildpackName
}

func (c *config) GetBinaryBuildpackName() string {
	return *c.BinaryBuildpackName
}

func (c *config) GetStaticFileBuildpackName() string {
	return *c.StaticFileBuildpackName
}

func (c *config) GetPrivateDockerRegistryImage() string {
	return *c.PrivateDockerRegistryImage
}

func (c *config) GetPrivateDockerRegistryUsername() string {
	return *c.PrivateDockerRegistryUsername
}

func (c *config) GetPrivateDockerRegistryPassword() string {
	return *c.PrivateDockerRegistryPassword
}

func (c *config) GetPublicDockerAppImage() string {
	return *c.PublicDockerAppImage
}

func (c *config) GetUnallocatedIPForSecurityGroup() string {
	return *c.UnallocatedIPForSecurityGroup
}

func (c *config) GetRequireProxiedAppTraffic() bool {
	return *c.RequireProxiedAppTraffic
}

func (c *config) GetStacks() []string {
	return *c.Stacks
}

func (c *config) GetUseWindowsTestTask() bool {
	return *c.UseWindowsTestTask
}

func (c *config) GetUseWindowsContextPath() bool {
	return *c.UseWindowsContextPath
}

func (c *config) GetWindowsStack() string {
	return "windows"
}

func (c *config) GetVolumeServiceName() string {
	return *c.VolumeServiceName
}

func (c *config) GetVolumeServicePlanName() string {
	return *c.VolumeServicePlanName
}

func (c *config) GetVolumeServiceCreateConfig() string {
	return *c.VolumeServiceCreateConfig
}

func (c *config) GetAdminClient() string {
	return ""
}

func (c *config) GetAdminClientSecret() string {
	return ""
}

func (c *config) GetExistingClient() string {
	return ""
}

func (c *config) GetExistingClientSecret() string {
	return ""
}

func (c *config) GetReporterConfig() reporterConfig {
	reporterConfigFromConfig := c.ReporterConfig

	if reporterConfigFromConfig != nil {
		return *reporterConfigFromConfig
	}

	return reporterConfig{}
}

func (c *config) RunningOnK8s() bool {
	return *c.Infrastructure == "kubernetes"
}
