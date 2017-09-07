package internal

import (
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/commandstarter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
)

type TestSpace struct {
	QuotaDefinitionName                  string
	organizationName                     string
	spaceName                            string
	isPersistent                         bool
	isExistingOrganization               bool
	isExistingSpace                      bool
	QuotaDefinitionTotalMemoryLimit      string
	QuotaDefinitionInstanceMemoryLimit   string
	QuotaDefinitionRoutesLimit           string
	QuotaDefinitionAppInstanceLimit      string
	QuotaDefinitionServiceInstanceLimit  string
	QuotaDefinitionAllowPaidServicesFlag string
	QuotaDefinitionReservedRoutePorts    string
	CommandStarter                       internal.Starter
	Timeout                              time.Duration
}

type spaceConfig interface {
	GetScaledTimeout(time.Duration) time.Duration
	GetPersistentAppSpace() string
	GetPersistentAppOrg() string
	GetPersistentAppQuotaName() string
	GetNamePrefix() string
	GetUseExistingOrganization() bool
	GetUseExistingSpace() bool
	GetExistingOrganization() string
	GetExistingSpace() string
}

type Space interface {
	Create()
	Destroy()
	ShouldRemain() bool
	OrganizationName() string
}

func NewRegularTestSpace(cfg spaceConfig, quotaLimit string) *TestSpace {
	organizationName, _ := organizationName(cfg)
	spaceName := spaceName(cfg)
	return NewBaseTestSpace(
		spaceName,
		organizationName,
		generator.PrefixedRandomName(cfg.GetNamePrefix(), "QUOTA"),
		quotaLimit,
		false,
		cfg.GetUseExistingOrganization(),
		cfg.GetUseExistingSpace(),
		cfg.GetScaledTimeout(1*time.Minute),
		commandstarter.NewCommandStarter(),
	)
}

func NewPersistentAppTestSpace(cfg spaceConfig) *TestSpace {
	baseTestSpace := NewBaseTestSpace(
		cfg.GetPersistentAppSpace(),
		cfg.GetPersistentAppOrg(),
		cfg.GetPersistentAppQuotaName(),
		"10G",
		true,
		cfg.GetUseExistingOrganization(),
		cfg.GetUseExistingSpace(),
		cfg.GetScaledTimeout(1*time.Minute),
		commandstarter.NewCommandStarter(),
	)
	return baseTestSpace
}

func NewBaseTestSpace(spaceName, organizationName, quotaDefinitionName, quotaDefinitionTotalMemoryLimit string, isPersistent bool, isExistingOrganization bool, isExistingSpace bool, timeout time.Duration, cmdStarter internal.Starter) *TestSpace {
	testSpace := &TestSpace{
		QuotaDefinitionName:                  quotaDefinitionName,
		QuotaDefinitionTotalMemoryLimit:      quotaDefinitionTotalMemoryLimit,
		QuotaDefinitionInstanceMemoryLimit:   "-1",
		QuotaDefinitionRoutesLimit:           "1000",
		QuotaDefinitionAppInstanceLimit:      "-1",
		QuotaDefinitionServiceInstanceLimit:  "100",
		QuotaDefinitionAllowPaidServicesFlag: "--allow-paid-service-plans",
		QuotaDefinitionReservedRoutePorts:    "20",
		organizationName:                     organizationName,
		spaceName:                            spaceName,
		CommandStarter:                       cmdStarter,
		Timeout:                              timeout,
		isPersistent:                         isPersistent,
		isExistingOrganization:               isExistingOrganization,
		isExistingSpace:                      isExistingSpace,
	}
	return testSpace
}

func (ts *TestSpace) Create() {
	args := []string{
		"create-quota",
		ts.QuotaDefinitionName,
		"-m", ts.QuotaDefinitionTotalMemoryLimit,
		"-i", ts.QuotaDefinitionInstanceMemoryLimit,
		"-r", ts.QuotaDefinitionRoutesLimit,
		"-a", ts.QuotaDefinitionAppInstanceLimit,
		"-s", ts.QuotaDefinitionServiceInstanceLimit,
		"--reserved-route-ports", ts.QuotaDefinitionReservedRoutePorts,
		ts.QuotaDefinitionAllowPaidServicesFlag,
	}

	if !ts.isExistingOrganization {
		createQuota := internal.Cf(ts.CommandStarter, args...)
		EventuallyWithOffset(1, createQuota, ts.Timeout).Should(Exit(0))

		createOrg := internal.Cf(ts.CommandStarter, "create-org", ts.organizationName)
		EventuallyWithOffset(1, createOrg, ts.Timeout).Should(Exit(0))

		setQuota := internal.Cf(ts.CommandStarter, "set-quota", ts.organizationName, ts.QuotaDefinitionName)
		EventuallyWithOffset(1, setQuota, ts.Timeout).Should(Exit(0))
	}

	if !ts.isExistingSpace {
		createSpace := internal.Cf(ts.CommandStarter, "create-space", "-o", ts.organizationName, ts.spaceName)
		EventuallyWithOffset(1, createSpace, ts.Timeout).Should(Exit(0))
	}
}

func (ts *TestSpace) Destroy() {
	if ts.isExistingSpace {
		return
	} else if ts.isExistingOrganization {
		deleteSpace := internal.Cf(ts.CommandStarter, "delete-space", "-f", "-o", ts.organizationName, ts.spaceName)
		EventuallyWithOffset(1, deleteSpace, ts.Timeout).Should(Exit(0))
	} else {
		deleteOrg := internal.Cf(ts.CommandStarter, "delete-org", "-f", ts.organizationName)
		EventuallyWithOffset(1, deleteOrg, ts.Timeout).Should(Exit(0))

		deleteQuota := internal.Cf(ts.CommandStarter, "delete-quota", "-f", ts.QuotaDefinitionName)
		EventuallyWithOffset(1, deleteQuota, ts.Timeout).Should(Exit(0))
	}
}

func (ts *TestSpace) OrganizationName() string {
	if ts == nil {
		return ""
	}
	return ts.organizationName
}

func (ts *TestSpace) SpaceName() string {
	if ts == nil {
		return ""
	}
	return ts.spaceName
}

func (ts *TestSpace) ShouldRemain() bool {
	return ts.isPersistent
}

func organizationName(cfg spaceConfig) (string, bool) {
	if cfg.GetUseExistingOrganization() {
		Expect(cfg.GetExistingOrganization()).ToNot(BeEmpty(), "existing_organization must be specified")
		return cfg.GetExistingOrganization(), true
	}
	return generator.PrefixedRandomName(cfg.GetNamePrefix(), "ORG"), false
}

func spaceName(cfg spaceConfig) string {
	if cfg.GetUseExistingSpace() {
		Expect(cfg.GetExistingSpace()).ToNot(BeEmpty(), "existing_space must be specified")
		return cfg.GetExistingSpace()
	}
	return generator.PrefixedRandomName(cfg.GetNamePrefix(), "SPACE")
}
