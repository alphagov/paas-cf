package workflowhelpers_test

import (
	"fmt"
	"os"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"

	. "github.com/onsi/ginkgo"
	ginkgoconfig "github.com/onsi/ginkgo/config"
	. "github.com/onsi/gomega"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
)

var _ = Describe("UserContext", func() {
	Describe("NewUserContext", func() {
		var testSpace *internal.TestSpace
		var testUser *internal.TestUser
		BeforeEach(func() {
			testSpace = internal.NewRegularTestSpace(&config.Config{}, "10G")
			testUser = internal.NewTestUser(&config.Config{}, &fakes.FakeCmdStarter{})
		})

		var createUser = func() workflowhelpers.UserContext {
			return workflowhelpers.NewUserContext("http://FAKE_API.example.com", testUser, testSpace, false, 1*time.Minute)
		}

		It("returns a UserContext struct", func() {
			Expect(createUser()).To(BeAssignableToTypeOf(workflowhelpers.UserContext{}))
		})

		It("sets UserContext.ApiUrl", func() {
			Expect(createUser().ApiUrl).To(Equal("http://FAKE_API.example.com"))
		})

		It("sets UserContext.Username", func() {
			Expect(createUser().Username).To(Equal(testUser.Username()))
		})

		It("sets UserContext.Password", func() {
			Expect(createUser().Password).To(Equal(testUser.Password()))
		})

		It("sets UserContext.Org", func() {
			Expect(createUser().Org).To(Equal(testSpace.OrganizationName()))
		})

		It("sets UserContext.Space", func() {
			Expect(createUser().Space).To(Equal(testSpace.SpaceName()))
		})

		It("sets the timeout for all cf commands", func() {
			Expect(createUser().Timeout).To(Equal(1 * time.Minute))
		})
	})

	Describe("Login", func() {
		var target, username, password, org, space string
		var skipSslValidation bool
		var timeout time.Duration
		var fakeStarter *fakes.FakeCmdStarter
		var testSpace *internal.TestSpace
		var testUser *internal.TestUser

		var userContext workflowhelpers.UserContext

		BeforeEach(func() {
			target = "http://FAKE_API.example.com"
			username = "FAKE_USERNAME"
			password = "FAKE_PASSWORD"
			org = "FAKE_ORG"
			space = "FAKE_SPACE"
			skipSslValidation = false
			timeout = 1 * time.Second

			fakeStarter = fakes.NewFakeCmdStarter()
			testSpace = internal.NewRegularTestSpace(&config.Config{}, "10G")

			testUser = internal.NewTestUser(&config.Config{}, &fakes.FakeCmdStarter{})
		})

		JustBeforeEach(func() {
			userContext = workflowhelpers.NewUserContext(target, testUser, testSpace, skipSslValidation, timeout)
			userContext.CommandStarter = fakeStarter
		})

		It("logs in the user", func() {
			userContext.Login()

			Expect(fakeStarter.CalledWith).To(HaveLen(2))

			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"api", target}))

			Expect(fakeStarter.CalledWith[1].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[1].Args).To(Equal([]string{"auth", testUser.Username(), testUser.Password()}))
		})

		Context("when SkipSSLValidation is true", func() {
			BeforeEach(func() {
				skipSslValidation = true
			})

			It("adds the --skip-ssl-validation flag to 'cf api'", func() {
				userContext.Login()

				Expect(fakeStarter.CalledWith).To(HaveLen(2))

				Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"api", target, "--skip-ssl-validation"}))
			})
		})

		Context("when the 'cf api' call fails", func() {
			BeforeEach(func() {
				fakeStarter.ToReturn[0].ExitCode = 1
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.Login()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
			})
		})

		Context("when 'cf api' times out", func() {
			BeforeEach(func() {
				timeout = 2 * time.Second
				fakeStarter.ToReturn[0].SleepTime = 3
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.Login()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
			})

		})

		Context("when the 'cf auth' call fails", func() {
			BeforeEach(func() {
				fakeStarter.ToReturn[1].ExitCode = 1
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.Login()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
			})
		})

		Context("when the 'cf auth' times out", func() {
			BeforeEach(func() {
				timeout = 2 * time.Second
				fakeStarter.ToReturn[1].SleepTime = 3
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.Login()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
			})
		})
	})

	Describe("SetCfHomeDir", func() {
		var userContext workflowhelpers.UserContext
		var previousCfHome string
		BeforeEach(func() {
			previousCfHome = "my-cf-home-dir"
			os.Setenv("CF_HOME", previousCfHome)

			userContext = workflowhelpers.UserContext{}
		})

		AfterEach(func() {
			os.Unsetenv("CF_HOME")
		})

		It("creates a temporary directory and sets CF_HOME to point to it", func() {
			tmpDirRegexp := fmt.Sprintf("(\\/var\\/folders\\/.*\\/.*\\/T|\\/tmp)\\/cf_home_%d", ginkgoconfig.GinkgoConfig.ParallelNode)

			userContext.SetCfHomeDir()
			cfHome := os.Getenv("CF_HOME")
			Expect(cfHome).To(MatchRegexp(tmpDirRegexp))
			Expect(cfHome).To(BeADirectory())
		})

		It("returns both the original and currently-used cf home directory", func() {
			originalCfHomeDir, currentCfHomeDir := userContext.SetCfHomeDir()
			Expect(originalCfHomeDir).To(Equal(previousCfHome))
			Expect(currentCfHomeDir).To(Equal(os.Getenv("CF_HOME")))
		})

		It("sets a unique CF_HOME value", func() {
			var firstHome, secondHome string

			_, firstHome = userContext.SetCfHomeDir()
			_, secondHome = userContext.SetCfHomeDir()

			Expect(firstHome).NotTo(Equal(secondHome))
		})

	})

	Describe("TargetSpace", func() {
		var userContext workflowhelpers.UserContext
		var timeout time.Duration
		var fakeStarter *fakes.FakeCmdStarter
		var testSpace *internal.TestSpace
		var testUser *internal.TestUser

		BeforeEach(func() {
			testSpace = internal.NewRegularTestSpace(&config.Config{}, "10G")
			timeout = 1 * time.Second
			fakeStarter = fakes.NewFakeCmdStarter()

			testUser = internal.NewTestUser(&config.Config{}, &fakes.FakeCmdStarter{})
		})

		JustBeforeEach(func() {
			userContext = workflowhelpers.NewUserContext("api-url", testUser, testSpace, false, timeout)
			userContext.CommandStarter = fakeStarter
		})

		It("targets the org and space", func() {
			userContext.TargetSpace()
			Expect(fakeStarter.CalledWith).To(HaveLen(1))
			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"target", "-o", testSpace.OrganizationName(), "-s", testSpace.SpaceName()}))
		})

		Context("when the test space is not set", func() {
			BeforeEach(func() {
				testSpace = nil
			})

			It("does not target anything", func() {
				userContext.TargetSpace()
				Expect(fakeStarter.CalledWith).To(HaveLen(0))
			})
		})

		Context("when the target command times out", func() {
			BeforeEach(func() {
				timeout = 2 * time.Second
				fakeStarter.ToReturn[0].SleepTime = 3
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.TargetSpace()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
			})
		})

		Context("when the target command returns a non-zero exit code", func() {
			BeforeEach(func() {
				fakeStarter.ToReturn[0].ExitCode = 1
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.TargetSpace()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
			})
		})
	})

	Describe("AddUserToSpace", func() {
		var userContext workflowhelpers.UserContext
		var fakeStarter *fakes.FakeCmdStarter
		var timeout time.Duration
		var testSpace *internal.TestSpace
		var testUser *internal.TestUser

		BeforeEach(func() {
			timeout = 1 * time.Second
			fakeStarter = fakes.NewFakeCmdStarter()
			testSpace = internal.NewRegularTestSpace(&config.Config{NamePrefix: "UNIT-TESTS"}, "10G")

			testUser = internal.NewTestUser(&config.Config{}, &fakes.FakeCmdStarter{})
		})

		JustBeforeEach(func() {
			userContext = workflowhelpers.NewUserContext("", testUser, testSpace, false, timeout)
			userContext.CommandStarter = fakeStarter
		})

		It("gives the user the SpaceManager role", func() {
			userContext.AddUserToSpace()
			Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 0))
			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"set-space-role", userContext.Username, testSpace.OrganizationName(), testSpace.SpaceName(), "SpaceManager"}))
		})

		It("gives the user the SpaceDeveloper role", func() {
			userContext.AddUserToSpace()
			Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 0))
			Expect(fakeStarter.CalledWith[1].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[1].Args).To(Equal([]string{"set-space-role", userContext.Username, testSpace.OrganizationName(), testSpace.SpaceName(), "SpaceDeveloper"}))
		})

		It("gives the user the SpaceAuditor role", func() {
			userContext.AddUserToSpace()
			Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 0))
			Expect(fakeStarter.CalledWith[2].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[2].Args).To(Equal([]string{"set-space-role", userContext.Username, testSpace.OrganizationName(), testSpace.SpaceName(), "SpaceAuditor"}))
		})

		Describe("failure cases", func() {
			testFailureCase := func(callIndex int) func() {
				return func() {
					BeforeEach(func() {
						fakeStarter.ToReturn[callIndex].ExitCode = 1
					})

					It("returns a ginkgo error", func() {
						failures := InterceptGomegaFailures(func() {
							userContext.AddUserToSpace()
						})

						Expect(failures[0]).To(MatchRegexp("not authorized"))
					})
				}
			}
			Context("when 'cf set-role SpaceManager' fails", testFailureCase(0))
			Context("when 'cf set-role SpaceDeveloper' fails", testFailureCase(1))
			Context("when 'cf set-role SpaceAuditor' fails", testFailureCase(2))
		})

		Describe("timing out", func() {
			testTimeoutCase := func(callIndex int) func() {
				return func() {
					BeforeEach(func() {
						fakeStarter.ToReturn[callIndex].SleepTime = 5
						timeout = 2 * time.Second
					})

					It("returns a ginkgo error", func() {
						failures := InterceptGomegaFailures(func() {
							userContext.AddUserToSpace()
						})

						Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
					})
				}
			}

			Context("when 'cf set-role SpaceManager' times out", testTimeoutCase(0))
			Context("when 'cf set-role SpaceDeveloper' times out", testTimeoutCase(1))
			Context("when 'cf set-role SpaceAuditor' times out", testTimeoutCase(2))
		})
	})

	Describe("Logout", func() {
		var userContext workflowhelpers.UserContext
		var fakeStarter *fakes.FakeCmdStarter
		var timeout time.Duration
		var testSpace *internal.TestSpace
		var testUser *internal.TestUser

		BeforeEach(func() {
			timeout = 1 * time.Second
			fakeStarter = fakes.NewFakeCmdStarter()
			testSpace = internal.NewRegularTestSpace(&config.Config{}, "10G")
			testUser = internal.NewTestUser(&config.Config{}, &fakes.FakeCmdStarter{})
		})

		JustBeforeEach(func() {
			userContext = workflowhelpers.NewUserContext("", testUser, testSpace, false, timeout)
			userContext.CommandStarter = fakeStarter
		})

		It("logs out the user", func() {
			userContext.Logout()

			Expect(fakeStarter.CalledWith).To(HaveLen(1))
			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"logout"}))
		})

		Context("when 'cf logout' exits with a non-zero exit code", func() {
			BeforeEach(func() {
				fakeStarter.ToReturn[0].ExitCode = 1
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.Logout()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
			})
		})

		Context("when 'cf logout' times out", func() {
			BeforeEach(func() {
				timeout = 2 * time.Second
				fakeStarter.ToReturn[0].SleepTime = 3
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					userContext.Logout()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
			})
		})
	})

	Describe("UnsetCfHomeDir", func() {
		var userContext workflowhelpers.UserContext
		var originalCfHomeDir, currentCfHomeDir string
		var testSpace *internal.TestSpace
		var testUser *internal.TestUser

		BeforeEach(func() {
			testSpace = internal.NewRegularTestSpace(&config.Config{}, "10G")
			testUser = internal.NewTestUser(&config.Config{}, &fakes.FakeCmdStarter{})
			userContext = workflowhelpers.NewUserContext("", testUser, testSpace, false, 1*time.Minute)
		})

		It("restores Cf home dir to its original value", func() {
			originalCfHomeDir, currentCfHomeDir = userContext.SetCfHomeDir()
			userContext.UnsetCfHomeDir(originalCfHomeDir, currentCfHomeDir)
			Expect(os.Getenv("CF_HOME")).To(Equal(originalCfHomeDir))
			Expect(currentCfHomeDir).NotTo(BeADirectory())
		})
	})
})
