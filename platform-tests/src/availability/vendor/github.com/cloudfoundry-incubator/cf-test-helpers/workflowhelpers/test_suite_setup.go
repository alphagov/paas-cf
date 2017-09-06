package workflowhelpers

import (
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/commandstarter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
)

type remoteResource interface {
	Create()
	Destroy()
	ShouldRemain() bool
}

type testSuiteConfig interface {
	GetApiEndpoint() string
	GetConfigurableTestPassword() string
	GetPersistentAppOrg() string
	GetPersistentAppQuotaName() string
	GetPersistentAppSpace() string
	GetScaledTimeout(time.Duration) time.Duration
	GetAdminPassword() string
	GetExistingUser() string
	GetExistingUserPassword() string
	GetShouldKeepUser() bool
	GetUseExistingUser() bool
	GetAdminUser() string
	GetUseExistingOrganization() bool
	GetUseExistingSpace() bool
	GetExistingOrganization() string
	GetExistingSpace() string
	GetSkipSSLValidation() bool
	GetNamePrefix() string
}

type ReproducibleTestSuiteSetup struct {
	shortTimeout time.Duration
	longTimeout  time.Duration

	organizationName string
	spaceName        string

	TestUser  remoteResource
	TestSpace internal.Space

	regularUserContext UserContext
	adminUserContext   UserContext

	SkipSSLValidation bool

	SkipUserCreation bool

	isPersistent bool

	originalCfHomeDir string
	currentCfHomeDir  string
}

const RUNAWAY_QUOTA_MEM_LIMIT = "99999G"

func NewTestSuiteSetup(config testSuiteConfig) *ReproducibleTestSuiteSetup {
	var testSpace *internal.TestSpace
	var testUser *internal.TestUser
	var adminUser *internal.TestUser

	testSpace = internal.NewRegularTestSpace(config, "10G")
	testUser = internal.NewTestUser(config, commandstarter.NewCommandStarter())
	adminUser = internal.NewAdminUser(config, commandstarter.NewCommandStarter())

	shortTimeout := config.GetScaledTimeout(1 * time.Minute)
	regularUserContext := NewUserContext(config.GetApiEndpoint(), testUser, testSpace, config.GetSkipSSLValidation(), shortTimeout)
	adminUserContext := NewUserContext(config.GetApiEndpoint(), adminUser, nil, config.GetSkipSSLValidation(), shortTimeout)

	return NewBaseTestSuiteSetup(config, testSpace, testUser, regularUserContext, adminUserContext, false)
}

func NewSmokeTestSuiteSetup(config testSuiteConfig) *ReproducibleTestSuiteSetup {
	var testSpace *internal.TestSpace
	var testUser *internal.TestUser
	var adminUser *internal.TestUser

	testSpace = internal.NewRegularTestSpace(config, "10G")
	testUser = internal.NewTestUser(config, commandstarter.NewCommandStarter())
	adminUser = internal.NewAdminUser(config, commandstarter.NewCommandStarter())

	shortTimeout := config.GetScaledTimeout(1 * time.Minute)
	regularUserContext := NewUserContext(config.GetApiEndpoint(), testUser, testSpace, config.GetSkipSSLValidation(), shortTimeout)
	adminUserContext := NewUserContext(config.GetApiEndpoint(), adminUser, nil, config.GetSkipSSLValidation(), shortTimeout)

	return NewBaseTestSuiteSetup(config, testSpace, testUser, regularUserContext, adminUserContext, true)
}

func NewPersistentAppTestSuiteSetup(config testSuiteConfig) *ReproducibleTestSuiteSetup {
	var testSpace *internal.TestSpace
	var testUser *internal.TestUser
	var adminUser *internal.TestUser

	testSpace = internal.NewPersistentAppTestSpace(config)
	testUser = internal.NewTestUser(config, commandstarter.NewCommandStarter())
	adminUser = internal.NewAdminUser(config, commandstarter.NewCommandStarter())

	shortTimeout := config.GetScaledTimeout(1 * time.Minute)
	regularUserContext := NewUserContext(config.GetApiEndpoint(), testUser, testSpace, config.GetSkipSSLValidation(), shortTimeout)
	adminUserContext := NewUserContext(config.GetApiEndpoint(), adminUser, nil, config.GetSkipSSLValidation(), shortTimeout)

	testSuiteSetup := NewBaseTestSuiteSetup(config, testSpace, testUser, regularUserContext, adminUserContext, false)
	testSuiteSetup.isPersistent = true

	return testSuiteSetup
}

func NewRunawayAppTestSuiteSetup(config testSuiteConfig) *ReproducibleTestSuiteSetup {
	testSpace := internal.NewRegularTestSpace(config, RUNAWAY_QUOTA_MEM_LIMIT)
	testUser := internal.NewTestUser(config, commandstarter.NewCommandStarter())
	adminUser := internal.NewAdminUser(config, commandstarter.NewCommandStarter())

	shortTimeout := config.GetScaledTimeout(1 * time.Minute)
	regularUserContext := NewUserContext(config.GetApiEndpoint(), testUser, testSpace, config.GetSkipSSLValidation(), shortTimeout)
	adminUserContext := NewUserContext(config.GetApiEndpoint(), adminUser, nil, config.GetSkipSSLValidation(), shortTimeout)

	return NewBaseTestSuiteSetup(config, testSpace, testUser, regularUserContext, adminUserContext, false)
}

func NewBaseTestSuiteSetup(config testSuiteConfig, testSpace internal.Space, testUser remoteResource, regularUserContext, adminUserContext UserContext, skipUserCreation bool) *ReproducibleTestSuiteSetup {
	shortTimeout := config.GetScaledTimeout(1 * time.Minute)

	return &ReproducibleTestSuiteSetup{
		shortTimeout: shortTimeout,
		longTimeout:  config.GetScaledTimeout(5 * time.Minute),

		regularUserContext: regularUserContext,
		adminUserContext:   adminUserContext,

		isPersistent:     false,
		SkipUserCreation: skipUserCreation,
		TestSpace:        testSpace,
		TestUser:         testUser,
	}
}

func (testSetup ReproducibleTestSuiteSetup) GetOrganizationName() string {
	return testSetup.TestSpace.OrganizationName()
}

func (testSetup ReproducibleTestSuiteSetup) ShortTimeout() time.Duration {
	return testSetup.shortTimeout
}

func (testSetup ReproducibleTestSuiteSetup) LongTimeout() time.Duration {
	return testSetup.longTimeout
}

func (testSetup *ReproducibleTestSuiteSetup) Setup() {
	AsUser(testSetup.AdminUserContext(), testSetup.shortTimeout, func() {
		testSetup.TestSpace.Create()
		if !testSetup.SkipUserCreation {
			testSetup.TestUser.Create()
		}
		testSetup.regularUserContext.AddUserToSpace()
	})
	testSetup.originalCfHomeDir, testSetup.currentCfHomeDir = testSetup.regularUserContext.SetCfHomeDir()
	testSetup.regularUserContext.Login()
	testSetup.regularUserContext.TargetSpace()
}

func (testSetup *ReproducibleTestSuiteSetup) Teardown() {
	testSetup.regularUserContext.Logout()
	testSetup.regularUserContext.UnsetCfHomeDir(testSetup.originalCfHomeDir, testSetup.currentCfHomeDir)

	AsUser(testSetup.AdminUserContext(), testSetup.shortTimeout, func() {
		if !testSetup.TestUser.ShouldRemain() {
			if !testSetup.SkipUserCreation {
				testSetup.TestUser.Destroy()
			}
		}

		if !testSetup.TestSpace.ShouldRemain() {
			testSetup.TestSpace.Destroy()
		}
	})
}

func (testSetup *ReproducibleTestSuiteSetup) AdminUserContext() UserContext {
	return testSetup.adminUserContext
}

func (testSetup *ReproducibleTestSuiteSetup) RegularUserContext() UserContext {
	return testSetup.regularUserContext
}
