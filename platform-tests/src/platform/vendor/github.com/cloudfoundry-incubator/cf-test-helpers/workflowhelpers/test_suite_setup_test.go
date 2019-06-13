package workflowhelpers_test

import (
	"os"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	starterFakes "github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal/fakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("ReproducibleTestSuiteSetup", func() {
	Describe("NewBaseTestSuiteSetup", func() {
		var cfg config.Config
		var apiEndpoint string
		var skipSSLValidation bool
		var shortTimeout time.Duration
		var testUser *internal.TestUser
		var testSpace *internal.TestSpace

		var regularUserContext, adminUserContext UserContext

		BeforeEach(func() {
			apiEndpoint = "api.my-cf.com"
			skipSSLValidation = false
		})

		JustBeforeEach(func() {
			cfg = config.Config{
				TimeoutScale:      2.0,
				NamePrefix:        "UNIT-TESTS",
				SkipSSLValidation: skipSSLValidation,
				ApiEndpoint:       apiEndpoint,
				AdminUser:         "admin",
				AdminPassword:     "admin-password",
			}
			testSpace = internal.NewRegularTestSpace(&cfg, "10G")
			testUser = internal.NewTestUser(&cfg, starterFakes.NewFakeCmdStarter())
			shortTimeout = cfg.GetScaledTimeout(1 * time.Minute)

			regularUserContext = NewUserContext(apiEndpoint, testUser, testSpace, skipSSLValidation, shortTimeout)
			adminUserContext = NewUserContext(apiEndpoint, internal.NewAdminUser(&cfg, starterFakes.NewFakeCmdStarter()), nil, skipSSLValidation, shortTimeout)
		})

		It("sets ShortTimeout to 1 Minute, scaled by the config", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
			Expect(setup.ShortTimeout()).To(Equal(time.Duration(cfg.TimeoutScale * float64(1*time.Minute))))
		})

		It("sets LongTimeout to 5 Minutes, scaled by the config", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
			Expect(setup.LongTimeout()).To(Equal(time.Duration(cfg.TimeoutScale * float64(5*time.Minute))))
		})

		It("sets the regularUserContext", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
			Expect(setup.RegularUserContext()).To(Equal(regularUserContext))
		})

		It("sets the adminUserContext", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
			Expect(setup.AdminUserContext()).To(Equal(adminUserContext))
		})

		It("sets the TestUser", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
			Expect(setup.TestUser).To(Equal(testUser))
		})

		It("sets the TestSpace", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
			Expect(setup.TestSpace).To(Equal(testSpace))
		})

		It("sets the OrganizationName to the testSpace's organiation name", func() {
			setup := NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)

			Expect(setup.GetOrganizationName()).To(Equal(testSpace.OrganizationName()))
		})
	})

	Describe("NewTestContextSuiteSetup", func() {
		var cfg config.Config
		var existingUserCfg config.Config

		BeforeEach(func() {
			cfg = config.Config{
				TimeoutScale:  2.0,
				NamePrefix:    "UNIT-TESTS",
				ApiEndpoint:   "api.my-cf.com",
				AdminUser:     "admin",
				AdminPassword: "admin-password",
			}

			existingUserCfg = config.Config{
				UseExistingUser:      true,
				ExistingUser:         "existing-user",
				ExistingUserPassword: "existing-user-password",
			}
		})

		Describe("regular user", func() {
			It("has a regular TestSpace", func() {
				setup := NewTestSuiteSetup(&cfg)
				testSpace, ok := setup.TestSpace.(*internal.TestSpace)
				Expect(ok).To(BeTrue())

				Expect(testSpace.OrganizationName()).To(MatchRegexp("UNIT-TESTS-[0-9]+-ORG-.*"))
				Expect(testSpace.SpaceName()).To(MatchRegexp("UNIT-TESTS-[0-9]+-SPACE-.*"))
			})

			It("has a regular TestUser", func() {
				setup := NewTestSuiteSetup(&cfg)
				Expect(setup.RegularUserContext().TestUser.Username()).To(MatchRegexp("UNIT-TESTS-[0-9]+-USER-.*"))
				Expect(len(setup.RegularUserContext().TestUser.Password())).To(Equal(20))
				Expect(setup.RegularUserContext().UseClientCredentials).To(BeFalse())
			})

			It("uses the api endpoint and SkipSSLValidation from the config", func() {
				setup := NewTestSuiteSetup(&cfg)
				Expect(setup.RegularUserContext().ApiUrl).To(Equal("api.my-cf.com"))
				Expect(setup.RegularUserContext().SkipSSLValidation).To(Equal(false))

				cfg.ApiEndpoint = "api.other-cf.com"
				cfg.SkipSSLValidation = true
				setup = NewTestSuiteSetup(&cfg)
				Expect(setup.RegularUserContext().ApiUrl).To(Equal("api.other-cf.com"))
				Expect(setup.RegularUserContext().SkipSSLValidation).To(BeTrue())
			})

			It("uses the short timeout", func() {
				setup := NewTestSuiteSetup(&cfg)
				Expect(setup.RegularUserContext().Timeout).To(Equal(setup.ShortTimeout()))
			})
		})

		Context("admin user", func() {
			It("creates an AdminUserContext from the config", func() {
				setup := NewTestSuiteSetup(&cfg)
				adminUserContext := setup.AdminUserContext()
				Expect(adminUserContext.ApiUrl).To(Equal(cfg.ApiEndpoint))
				Expect(adminUserContext.Username).To(Equal(cfg.AdminUser))
				Expect(adminUserContext.Password).To(Equal(cfg.AdminPassword))
				Expect(adminUserContext.TestSpace).To(BeNil())
				Expect(adminUserContext.SkipSSLValidation).To(Equal(cfg.SkipSSLValidation))
				Expect(adminUserContext.Timeout).To(Equal(cfg.GetScaledTimeout(1 * time.Minute)))
				Expect(adminUserContext.UseClientCredentials).To(BeFalse())
			})
		})

		It("uses the existing user", func() {
			setup := NewTestSuiteSetup(&existingUserCfg)
			regularUserContext := setup.RegularUserContext()
			Expect(setup.SkipUserCreation).To(Equal(existingUserCfg.UseExistingUser))
			Expect(regularUserContext.TestUser.Username()).To(Equal(existingUserCfg.ExistingUser))
			Expect(regularUserContext.TestUser.Password()).To(Equal(existingUserCfg.ExistingUserPassword))
		})

		Context("Admin Client", func() {
			BeforeEach(func() {
				cfg = config.Config{
					AdminClient:       "admin-client",
					AdminClientSecret: "admin-client-secret",
				}
			})

			It("can create admin user context given client credentials", func() {
				setup := NewTestSuiteSetup(&cfg)

				adminUserContext := setup.AdminUserContext()
				Expect(adminUserContext.Username).To(Equal(cfg.AdminClient))
				Expect(adminUserContext.Password).To(Equal(cfg.AdminClientSecret))
				Expect(adminUserContext.UseClientCredentials).To(BeTrue())
			})

			Context("when admin user is provided", func() {
				BeforeEach(func() {
					cfg.AdminUser = "should-not-be-used"
					cfg.AdminPassword = "should-not-be-used-password"
				})

				It("doesn't create admin user context with client credentials if only client name is provided", func() {
					cfg.AdminClientSecret = ""

					setup := NewTestSuiteSetup(&cfg)
					adminUserContext := setup.AdminUserContext()
					Expect(adminUserContext.Username).To(Equal(cfg.AdminUser))
					Expect(adminUserContext.Password).To(Equal(cfg.AdminPassword))
				})

				It("doesn't create admin user context with client credentials if only client secret is provided", func() {
					cfg.AdminClient = ""

					setup := NewTestSuiteSetup(&cfg)
					adminUserContext := setup.AdminUserContext()
					Expect(adminUserContext.Username).To(Equal(cfg.AdminUser))
					Expect(adminUserContext.Password).To(Equal(cfg.AdminPassword))
				})

				It("prefers client credentials when both are provided", func() {
					setup := NewTestSuiteSetup(&cfg)
					adminUserContext := setup.AdminUserContext()
					Expect(adminUserContext.Username).To(Equal(cfg.AdminClient))
					Expect(adminUserContext.Password).To(Equal(cfg.AdminClientSecret))
				})
			})
		})

		Context("Existing (regular) Client", func() {
			BeforeEach(func() {
				cfg = config.Config{
					NamePrefix:           "CF_SMOKE_TESTS",
					ExistingClient:       "client",
					ExistingClientSecret: "client-secret",
				}
			})

			It("can create regular user context given client credentials", func() {
				setup := NewTestSuiteSetup(&cfg)

				regularUserContext := setup.RegularUserContext()
				Expect(regularUserContext.Username).To(Equal(cfg.ExistingClient))
				Expect(regularUserContext.Password).To(Equal(cfg.ExistingClientSecret))
				Expect(regularUserContext.UseClientCredentials).To(BeTrue())
				Expect(setup.SkipUserCreation).To(BeTrue())
			})

			It("doesn't create regular user context with client credentials if only client name is provided", func() {
				cfg.ExistingClientSecret = ""

				setup := NewTestSuiteSetup(&cfg)

				regularUserContext := setup.RegularUserContext()
				Expect(regularUserContext.Username).To(ContainSubstring(cfg.NamePrefix))
			})

			It("doesn't create regular user context with client credentials if only client secret is provided", func() {
				cfg.ExistingClient = ""

				setup := NewTestSuiteSetup(&cfg)

				regularUserContext := setup.RegularUserContext()
				Expect(regularUserContext.Username).To(ContainSubstring(cfg.NamePrefix))
			})

			It("prefers client credentials when both are provided", func() {
				cfg.UseExistingUser = true
				cfg.ExistingUser = "user"
				cfg.ExistingUserPassword = "password"

				setup := NewTestSuiteSetup(&cfg)

				regularUserContext := setup.RegularUserContext()
				Expect(regularUserContext.Username).To(Equal(cfg.ExistingClient))
				Expect(regularUserContext.Password).To(Equal(cfg.ExistingClientSecret))
				Expect(setup.SkipUserCreation).To(BeTrue())
			})
		})
	})

	Describe("NewSmokeTestSuiteSetup", func() {
		It("always skips user creation", func() {
			cfg := config.Config{
				UseExistingUser: false,
			}

			setup := NewSmokeTestSuiteSetup(&cfg)

			Expect(setup.SkipUserCreation).To(BeTrue())
		})
	})

	Describe("Setup", func() {
		var testSpace *fakes.FakeSpace
		var testUser *fakes.FakeRemoteResource
		var fakeRegularUserValues, fakeAdminUserValues *fakes.FakeUserValues
		var fakeSpaceValues *fakes.FakeSpaceValues
		var regularUserCmdStarter, adminUserCmdStarter *starterFakes.FakeCmdStarter
		var regularUserContext, adminUserContext UserContext
		var cfg config.Config
		var apiUrl string
		var testSetup *ReproducibleTestSuiteSetup

		BeforeEach(func() {
			apiUrl = "api-url.com"
			testSpace = &fakes.FakeSpace{}
			testUser = &fakes.FakeRemoteResource{}

			regularUserCmdStarter = starterFakes.NewFakeCmdStarter()
			adminUserCmdStarter = starterFakes.NewFakeCmdStarter()

			fakeRegularUserValues = fakes.NewFakeUserValues("username", "password")
			fakeAdminUserValues = fakes.NewFakeUserValues("admin", "admin")
			fakeSpaceValues = fakes.NewFakeSpaceValues("org", "space")

			regularUserContext = UserContext{
				ApiUrl:         apiUrl,
				CommandStarter: regularUserCmdStarter,
				TestUser:       fakeRegularUserValues,
				Timeout:        2 * time.Second,
				TestSpace:      fakeSpaceValues,
			}

			adminUserContext = UserContext{
				ApiUrl:         apiUrl,
				CommandStarter: adminUserCmdStarter,
				TestUser:       fakeAdminUserValues,
				Timeout:        2 * time.Second,
			}
			cfg = config.Config{
				AddExistingUserToExistingSpace: true,
			}
		})

		JustBeforeEach(func() {
			testSetup = NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
		})

		It("logs in as the admin", func() {
			testSetup.Setup()
			Expect(adminUserCmdStarter.TotalCallsToStart).To(BeNumerically(">=", 2))

			Expect(adminUserCmdStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(adminUserCmdStarter.CalledWith[0].Args).To(Equal([]string{"api", apiUrl}))

			Expect(adminUserCmdStarter.CalledWith[1].Executable).To(Equal("cf"))
			Expect(adminUserCmdStarter.CalledWith[1].Args).To(Equal([]string{"auth", "admin", "admin"}))
		})

		It("creates the user on the remote CF Api", func() {
			testSetup.Setup()
			Expect(testUser.CreateCallCount()).To(Equal(1))
			Expect(adminUserCmdStarter.TotalCallsToStart).To(Equal(3))
		})

		It("creates the space on the remote CF api", func() {
			testSetup.Setup()
			Expect(testSpace.CreateCallCount()).To(Equal(1))
		})

		It("adds the user to the space", func() {
			testSetup.Setup()
			Expect(regularUserCmdStarter.TotalCallsToStart).To(BeNumerically(">=", 3))

			Expect(regularUserCmdStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[0].Args).To(Equal([]string{"set-space-role", fakeRegularUserValues.Username(), fakeSpaceValues.OrganizationName(), fakeSpaceValues.SpaceName(), "SpaceManager"}))
			Expect(regularUserCmdStarter.CalledWith[1].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[1].Args).To(Equal([]string{"set-space-role", fakeRegularUserValues.Username(), fakeSpaceValues.OrganizationName(), fakeSpaceValues.SpaceName(), "SpaceDeveloper"}))
			Expect(regularUserCmdStarter.CalledWith[2].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[2].Args).To(Equal([]string{"set-space-role", fakeRegularUserValues.Username(), fakeSpaceValues.OrganizationName(), fakeSpaceValues.SpaceName(), "SpaceAuditor"}))
		})

		It("logs in as the regular user in a unique CF_HOME and targets the correct space", func() {
			originalCfHomeDir := "originl-cf-home-dir"
			os.Setenv("CF_HOME", originalCfHomeDir)
			testSetup.Setup()
			Expect(os.Getenv("CF_HOME")).To(MatchRegexp("cf_home_.*"))
			Expect(os.Getenv("CF_HOME")).NotTo(Equal(originalCfHomeDir))

			Expect(regularUserCmdStarter.TotalCallsToStart).To(BeNumerically(">=", 6))
			Expect(regularUserCmdStarter.CalledWith[3].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[3].Args).To(Equal([]string{"api", apiUrl}))
			Expect(regularUserCmdStarter.CalledWith[4].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[4].Args).To(Equal([]string{"auth", fakeRegularUserValues.Username(), fakeRegularUserValues.Password()}))
			Expect(regularUserCmdStarter.CalledWith[5].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[5].Args).To(Equal([]string{"target", "-o", fakeSpaceValues.OrganizationName(), "-s", fakeSpaceValues.SpaceName()}))
		})

		It("skips creating the user when called with skipUserCreation on", func() {
			testSetup = NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, true)
			testSetup.Setup()
			Expect(testUser.CreateCallCount()).To(Equal(0))
		})
	})

	Describe("TearDown", func() {
		var testSpace *fakes.FakeSpace
		var testUser *fakes.FakeRemoteResource
		var fakeRegularUserValues, fakeAdminUserValues *fakes.FakeUserValues
		var fakeSpaceValues *fakes.FakeSpaceValues
		var regularUserCmdStarter, adminUserCmdStarter *starterFakes.FakeCmdStarter
		var regularUserContext, adminUserContext UserContext
		var cfg config.Config
		var apiUrl string
		var testSetup *ReproducibleTestSuiteSetup

		BeforeEach(func() {
			apiUrl = "api-url.com"
			testSpace = &fakes.FakeSpace{}
			testUser = &fakes.FakeRemoteResource{}

			regularUserCmdStarter = starterFakes.NewFakeCmdStarter()
			adminUserCmdStarter = starterFakes.NewFakeCmdStarter()

			fakeRegularUserValues = fakes.NewFakeUserValues("username", "password")
			fakeAdminUserValues = fakes.NewFakeUserValues("admin", "admin")
			fakeSpaceValues = fakes.NewFakeSpaceValues("org", "space")

			regularUserContext = UserContext{
				ApiUrl:         apiUrl,
				CommandStarter: regularUserCmdStarter,
				TestUser:       fakeRegularUserValues,
				Timeout:        2 * time.Second,
				TestSpace:      fakeSpaceValues,
			}

			adminUserContext = UserContext{
				ApiUrl:         apiUrl,
				CommandStarter: adminUserCmdStarter,
				TestUser:       fakeAdminUserValues,
				Timeout:        2 * time.Second,
			}
			cfg = config.Config{}
		})

		JustBeforeEach(func() {
			testSetup = NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, false)
		})

		It("logs out the regular user", func() {
			testSetup.Teardown()
			Expect(regularUserCmdStarter.TotalCallsToStart).To(BeNumerically(">=", 1))
			Expect(regularUserCmdStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(regularUserCmdStarter.CalledWith[0].Args).To(Equal([]string{"logout"}))
		})

		It("restores cf home directory", func() {
			originalCfHomeDir := "originl-cf-home-dir"
			os.Setenv("CF_HOME", originalCfHomeDir)

			testSetup.Setup()
			Expect(os.Getenv("CF_HOME")).NotTo(Equal(originalCfHomeDir))

			testSetup.Teardown()
			Expect(os.Getenv("CF_HOME")).To(Equal(originalCfHomeDir))
		})

		It("logs in as an admin", func() {
			testSetup.Teardown()
			Expect(adminUserCmdStarter.TotalCallsToStart).To(BeNumerically(">=", 2))

			Expect(adminUserCmdStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(adminUserCmdStarter.CalledWith[0].Args).To(Equal([]string{"api", apiUrl}))

			Expect(adminUserCmdStarter.CalledWith[1].Executable).To(Equal("cf"))
			Expect(adminUserCmdStarter.CalledWith[1].Args).To(Equal([]string{"auth", "admin", "admin"}))
		})

		It("destroys the user", func() {
			testSetup.Teardown()
			Expect(testUser.DestroyCallCount()).To(Equal(1))
		})

		Context("when the user should remain", func() {
			BeforeEach(func() {
				testUser.ShouldRemainReturns = true
			})

			It("does not destroy the user", func() {
				testSetup.Teardown()
				Expect(testUser.DestroyCallCount()).To(Equal(0))
			})

		})
		Context("when the user was not created", func() {
			JustBeforeEach(func() {
				testSetup = NewBaseTestSuiteSetup(&cfg, testSpace, testUser, regularUserContext, adminUserContext, true)
			})

			It("does not destroy the user", func() {
				testSetup.Teardown()
				Expect(testUser.DestroyCallCount()).To(Equal(0))
			})
		})

		It("destroys the space", func() {
			testSetup.Teardown()
			Expect(testSpace.DestroyCallCount()).To(Equal(1))
		})

	})
})
