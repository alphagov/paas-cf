package internal_test

import (
	"fmt"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("User", func() {
	var cfg *config.Config

	Describe("NewTestUser", func() {
		var existingUser, existingUserPassword string
		var useExistingUser bool
		var configurableTestPassword string

		BeforeEach(func() {
			useExistingUser = false
			configurableTestPassword = ""
		})

		JustBeforeEach(func() {
			cfg = &config.Config{
				NamePrefix:               "UNIT-TESTS",
				UseExistingUser:          useExistingUser,
				ExistingUser:             existingUser,
				ExistingUserPassword:     existingUserPassword,
				ConfigurableTestPassword: configurableTestPassword,
			}
		})

		It("has a random username and hard-coded password", func() {
			user := NewTestUser(cfg, &fakes.FakeCmdStarter{})
			Expect(user.Username()).To(MatchRegexp("UNIT-TESTS-USER-[0-9]+-.*"))
			Expect(user.Password()).To(Equal("meow"))
		})

		Context("when the config specifies that an existing user should be used", func() {
			BeforeEach(func() {
				useExistingUser = true
				existingUser = "my-test-user"
				existingUserPassword = "my-test-password"
			})

			It("uses the ExistingUser and ExistingUserPassword", func() {
				user := NewTestUser(cfg, &fakes.FakeCmdStarter{})
				Expect(user.Username()).To(Equal(existingUser))
				Expect(user.Password()).To(Equal(existingUserPassword))
			})
		})

		Context("when the config includes a ConfigurableTestPassword", func() {
			BeforeEach(func() {
				configurableTestPassword = "pre-configured-test-password"
			})

			It("uses the a random user name and the ConfigurableTestPassword", func() {
				user := NewTestUser(cfg, &fakes.FakeCmdStarter{})
				Expect(user.Username()).To(MatchRegexp("UNIT-TESTS-USER-[0-9]+-.*"))
				Expect(user.Password()).To(Equal(configurableTestPassword))
			})
		})
	})

	Describe("NewAdminUser", func() {
		It("copies the username and password from the config", func() {
			cfg := &config.Config{AdminUser: "admin", AdminPassword: "admin-password"}
			user := NewAdminUser(cfg, &fakes.FakeCmdStarter{})
			Expect(user.Username()).To(Equal("admin"))
			Expect(user.Password()).To(Equal("admin-password"))

			cfg = &config.Config{AdminUser: "admin-user-2", AdminPassword: "admin-password-2"}
			user = NewAdminUser(cfg, &fakes.FakeCmdStarter{})
			Expect(user.Username()).To(Equal("admin-user-2"))
			Expect(user.Password()).To(Equal("admin-password-2"))
		})
	})

	Describe("CreateUser", func() {
		var user *TestUser
		var fakeStarter *fakes.FakeCmdStarter
		var timeoutScale float64

		BeforeEach(func() {
			fakeStarter = fakes.NewFakeCmdStarter()
			timeoutScale = 1.0
		})

		JustBeforeEach(func() {
			cfg = &config.Config{
				TimeoutScale:         timeoutScale,
				UseExistingUser:      true,
				ExistingUser:         "my-username",
				ExistingUserPassword: "my-password",
			}

			user = NewTestUser(cfg, fakeStarter)
		})

		It("creates the user", func() {
			user.Create()
			Expect(fakeStarter.CalledWith).To(HaveLen(1))
			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"create-user", user.Username(), user.Password()}))
		})

		Context("when 'cf create-user' exits with a non-zero exit code", func() {
			BeforeEach(func() {
				fakeStarter.ToReturn[0].ExitCode = 1
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					user.Create()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("scim_resource_already_exists"))
			})

			Context("and the output mentions that the user already exists", func() {
				BeforeEach(func() {
					fakeStarter.ToReturn[0].Output = "scim_resource_already_exists"
				})

				It("considers the command successful and does not fail", func() {
					failures := InterceptGomegaFailures(func() {
						user.Create()
					})
					Expect(failures).To(BeEmpty())
				})
			})

			Context("and it redacts the password", func() {
				JustBeforeEach(func() {
					fakeStarter.ToReturn[0].Output = fmt.Sprintf("blah blah %s %s", cfg.ExistingUser, cfg.ExistingUserPassword)
				})

				It("redactos", func() {
					failures := InterceptGomegaFailures(func() {
						user.Create()
					})
					Expect(failures[0]).NotTo(ContainSubstring(cfg.ExistingUserPassword))
					Expect(failures[0]).To(ContainSubstring("[REDACTED]"))
				})
			})

			Context("and stderr mentions that the user already exists", func() {
				BeforeEach(func() {
					fakeStarter.ToReturn[0].Stderr = "scim_resource_already_exists"
				})

				It("considers the command successful and does not fail", func() {
					failures := InterceptGomegaFailures(func() {
						user.Create()
					})
					Expect(failures).To(BeEmpty())
				})
			})
		})

		Context("when 'cf create-user' takes longer than the short timeout", func() {
			BeforeEach(func() {
				timeoutScale = 0.0334 // two-second timeout
				fakeStarter.ToReturn[0].SleepTime = 3
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					user.Create()
				})

				Expect(len(failures)).To(BeNumerically(">", 0))
				Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
			})
		})
	})

	Describe("Destroy", func() {
		var user *TestUser
		var fakeStarter *fakes.FakeCmdStarter
		var timeoutScale float64

		BeforeEach(func() {
			fakeStarter = fakes.NewFakeCmdStarter()
			timeoutScale = 1.0
		})

		JustBeforeEach(func() {
			cfg = &config.Config{
				TimeoutScale: timeoutScale,
			}
			user = NewTestUser(cfg, fakeStarter)
		})

		It("deletes the user", func() {
			user.Destroy()
			Expect(fakeStarter.CalledWith).To(HaveLen(1))
			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"delete-user", "-f", user.Username()}))
		})

		Context("when 'cf delete-user' exits with a non-zero exit code", func() {
			BeforeEach(func() {
				fakeStarter.ToReturn[0].ExitCode = 1
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					user.Destroy()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
			})
		})

		Context("when 'cf delete-user' times out", func() {
			BeforeEach(func() {
				timeoutScale = 0.0334 // two second timeout
				fakeStarter.ToReturn[0].SleepTime = 3
			})

			It("fails with a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					user.Destroy()
				})

				Expect(failures).To(HaveLen(1))
				Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
			})
		})
	})

	Describe("ShouldRemain", func() {
		var user *TestUser
		var fakeStarter *fakes.FakeCmdStarter
		var timeoutScale float64
		var shouldKeepUser bool

		BeforeEach(func() {
			fakeStarter = fakes.NewFakeCmdStarter()
			timeoutScale = 1.0
			shouldKeepUser = false
		})

		JustBeforeEach(func() {
			cfg = &config.Config{
				TimeoutScale:   timeoutScale,
				ShouldKeepUser: shouldKeepUser,
			}
			user = NewTestUser(cfg, fakeStarter)
		})

		It("returns false", func() {
			Expect(user.ShouldRemain()).To(BeFalse())
		})

		Context("when the config specifies that the user should not be deleted", func() {
			BeforeEach(func() {
				shouldKeepUser = true
			})

			It("returns true", func() {
				Expect(user.ShouldRemain()).To(BeTrue())
			})
		})
	})
})
