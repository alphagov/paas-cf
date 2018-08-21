package internal_test

import (
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("TestSpace", func() {
	var cfg config.Config
	var namePrefix string
	var quotaLimit string
	BeforeEach(func() {
		namePrefix = "UNIT-TEST"
		quotaLimit = "10G"
		cfg = config.Config{
			NamePrefix:   namePrefix,
			TimeoutScale: 1.0,
		}
	})

	Describe("NewRegularTestSpace", func() {
		It("generates a quotaDefinitionName", func() {
			testSpace := NewRegularTestSpace(&cfg, quotaLimit)
			Expect(testSpace.QuotaDefinitionName).To(MatchRegexp("%s-[0-9]-QUOTA-.*", namePrefix))
		})

		It("generates an organizationName", func() {
			testSpace := NewRegularTestSpace(&cfg, quotaLimit)
			Expect(testSpace.OrganizationName()).To(MatchRegexp("%s-[0-9]-ORG-.*", namePrefix))
		})

		It("generates a spaceName", func() {
			testSpace := NewRegularTestSpace(&cfg, quotaLimit)
			Expect(testSpace.SpaceName()).To(MatchRegexp("%s-[0-9]-SPACE-.*", namePrefix))
		})

		It("sets a timeout for cf commands", func() {
			testSpace := NewRegularTestSpace(&cfg, quotaLimit)
			Expect(testSpace.Timeout).To(Equal(1 * time.Minute))
		})

		Context("when the config scales the timeout", func() {
			BeforeEach(func() {
				cfg = config.Config{
					NamePrefix:   namePrefix,
					TimeoutScale: 2.0,
				}
			})

			It("scales the timeout for cf commands", func() {
				testSpace := NewRegularTestSpace(&cfg, quotaLimit)
				Expect(testSpace.Timeout).To(Equal(2 * time.Minute))
			})
		})

		It("uses default values for the quota (except for QuotaDefinitionTotalMemoryLimit)", func() {
			testSpace := NewRegularTestSpace(&cfg, quotaLimit)
			Expect(testSpace.QuotaDefinitionInstanceMemoryLimit).To(Equal("-1"))
			Expect(testSpace.QuotaDefinitionRoutesLimit).To(Equal("1000"))
			Expect(testSpace.QuotaDefinitionAppInstanceLimit).To(Equal("-1"))
			Expect(testSpace.QuotaDefinitionServiceInstanceLimit).To(Equal("100"))
			Expect(testSpace.QuotaDefinitionAllowPaidServicesFlag).To(Equal("--allow-paid-service-plans"))
			Expect(testSpace.QuotaDefinitionReservedRoutePorts).To(Equal("20"))
		})

		It("uses the provided QuotaDefinitionTotalMemoryLimit", func() {
			testSpace := NewRegularTestSpace(&cfg, quotaLimit)
			Expect(testSpace.QuotaDefinitionTotalMemoryLimit).To(Equal(quotaLimit))
		})

		Context("when the config specifies that an existing organization should be used", func() {
			BeforeEach(func() {
				cfg = config.Config{
					UseExistingOrganization: true,
					ExistingOrganization:    "existing-org",
				}
			})
			It("uses the provided existing organization name", func() {
				testSpace := NewRegularTestSpace(&cfg, quotaLimit)
				Expect(testSpace.OrganizationName()).To(Equal("existing-org"))
			})
			Context("when the config does not specify the existing organization name", func() {
				BeforeEach(func() {
					cfg = config.Config{
						UseExistingOrganization: true,
					}
				})
				It("fails with a ginkgo error", func() {
					failures := InterceptGomegaFailures(func() {
						NewRegularTestSpace(&cfg, quotaLimit)
					})
					Expect(failures).To(ContainElement(ContainSubstring("existing_organization must be specified")))
				})
			})
		})

	})

	Describe("Create", func() {
		var testSpace *TestSpace
		var fakeStarter *fakes.FakeCmdStarter

		var spaceName, orgName, quotaName, quotaLimit string
		var isExistingOrganization, isExistingSpace bool
		var timeout time.Duration

		BeforeEach(func() {
			spaceName = "space"
			orgName = "org"
			quotaName = "quota"
			quotaLimit = "10G"
			isExistingOrganization = false
			isExistingSpace = false
			timeout = 1 * time.Second
			fakeStarter = fakes.NewFakeCmdStarter()
		})

		JustBeforeEach(func() {
			testSpace = NewBaseTestSpace(spaceName, orgName, quotaName, quotaLimit, isExistingOrganization, isExistingSpace, timeout, fakeStarter)
		})

		Context("when the organization name is not specified", func() {
			It("creates a quota", func() {
				testSpace.Create()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 0))
				Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{
					"create-quota", testSpace.QuotaDefinitionName,
					"-m", testSpace.QuotaDefinitionTotalMemoryLimit,
					"-i", testSpace.QuotaDefinitionInstanceMemoryLimit,
					"-r", testSpace.QuotaDefinitionRoutesLimit,
					"-a", testSpace.QuotaDefinitionAppInstanceLimit,
					"-s", testSpace.QuotaDefinitionServiceInstanceLimit,
					"--reserved-route-ports", testSpace.QuotaDefinitionReservedRoutePorts,
					testSpace.QuotaDefinitionAllowPaidServicesFlag,
				}))
			})

			It("creates an org", func() {
				testSpace.Create()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 1))
				Expect(fakeStarter.CalledWith[1].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[1].Args).To(Equal([]string{
					"create-org",
					testSpace.OrganizationName(),
				}))
			})

			It("sets the quota for the org", func() {
				testSpace.Create()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 2))
				Expect(fakeStarter.CalledWith[2].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[2].Args).To(Equal([]string{
					"set-quota",
					testSpace.OrganizationName(),
					testSpace.QuotaDefinitionName,
				}))
			})

			It("creates a space", func() {
				testSpace.Create()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 3))
				Expect(fakeStarter.CalledWith[3].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[3].Args).To(Equal([]string{
					"create-space",
					"-o",
					testSpace.OrganizationName(),
					testSpace.SpaceName(),
				}))
			})
		})

		Context("when the config specifies that an existing organization should be used", func() {
			BeforeEach(func() {
				isExistingOrganization = true
			})

			It("creates the space, but not the org or the quota, and does not set the quota", func() {
				testSpace.Create()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically("==", 1))
				Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{
					"create-space",
					"-o",
					testSpace.OrganizationName(),
					testSpace.SpaceName(),
				}))
			})
		})

		Describe("failure cases", func() {
			testFailureCase := func(callIndex int) func() {
				return func() {
					BeforeEach(func() {
						fakeStarter.ToReturn[callIndex].ExitCode = 1
					})

					It("returns a ginkgo error", func() {
						failures := InterceptGomegaFailures(func() {
							testSpace.Create()
						})
						Expect(failures).To(HaveLen(1))
						Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
					})
				}
			}

			Context("when 'cf create-quota' fails", testFailureCase(0))
			Context("when 'cf create-org' fails", testFailureCase(1))
			Context("when 'cf set-quota' fails", testFailureCase(2))
			Context("when 'cf create-space' fails", testFailureCase(3))
		})

		Describe("timing out", func() {
			BeforeEach(func() {
				timeout = 2 * time.Second
			})

			testTimeoutCase := func(callIndex int) func() {
				return func() {
					BeforeEach(func() {
						fakeStarter.ToReturn[callIndex].SleepTime = 5
					})

					It("returns a ginkgo error", func() {
						failures := InterceptGomegaFailures(func() {
							testSpace.Create()
						})

						Expect(failures).To(HaveLen(1))
						Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
					})
				}
			}

			Context("when 'cf create-quota' times out", testTimeoutCase(0))
			Context("when 'cf create-org' times out", testTimeoutCase(1))
			Context("when 'cf set-quota' times out", testTimeoutCase(2))
			Context("when 'cf create-space' times out", testTimeoutCase(3))
		})
	})

	Describe("Destroy", func() {
		var testSpace *TestSpace
		var fakeStarter *fakes.FakeCmdStarter
		var spaceName, orgName, quotaName, quotaLimit string
		var isExistingOrganization bool
		var isExistingSpace bool
		var timeout time.Duration
		BeforeEach(func() {
			fakeStarter = fakes.NewFakeCmdStarter()

			spaceName = "space"
			orgName = "org"
			quotaName = "quota"
			quotaLimit = "10G"
			isExistingOrganization = false
			isExistingSpace = false
			timeout = 1 * time.Second
		})

		JustBeforeEach(func() {
			testSpace = NewBaseTestSpace(
				spaceName,
				orgName,
				quotaName,
				quotaLimit,
				isExistingOrganization,
				isExistingSpace,
				timeout,
				fakeStarter,
			)
		})

		It("deletes the org", func() {
			testSpace.Destroy()
			Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 0))
			Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[0].Args).To(Equal([]string{"delete-org", "-f", testSpace.OrganizationName()}))
		})

		It("deletes the quota", func() {
			testSpace.Destroy()
			Expect(len(fakeStarter.CalledWith)).To(BeNumerically(">", 1))
			Expect(fakeStarter.CalledWith[1].Executable).To(Equal("cf"))
			Expect(fakeStarter.CalledWith[1].Args).To(Equal([]string{"delete-quota", "-f", testSpace.QuotaDefinitionName}))
		})

		Context("when the config specifies that an existing organization should be used", func() {
			BeforeEach(func() {
				isExistingOrganization = true
			})

			It("deletes the space, but does not delete the org or quota", func() {
				testSpace.Destroy()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically("==", 1))
				Expect(fakeStarter.CalledWith[0].Executable).To(Equal("cf"))
				Expect(fakeStarter.CalledWith[0].Args).To(Equal(
					[]string{"delete-space", "-f", "-o", testSpace.OrganizationName(), testSpace.SpaceName()}))
			})
		})

		Context("when the config specifies that an existing space should be used", func() {
			BeforeEach(func() {
				isExistingOrganization = true
				isExistingSpace = true
			})

			It("doesn't delete the space, the org, or the quota", func() {
				testSpace.Destroy()
				Expect(len(fakeStarter.CalledWith)).To(BeNumerically("==", 0))
			})
		})

		Describe("failure cases", func() {
			testFailureCase := func(callIndex int) func() {
				return func() {
					BeforeEach(func() {
						fakeStarter.ToReturn[callIndex].ExitCode = 1
					})

					It("returns a ginkgo error", func() {
						failures := InterceptGomegaFailures(func() {
							testSpace.Destroy()
						})
						Expect(failures).To(HaveLen(1))
						Expect(failures[0]).To(MatchRegexp("to match exit code:\n.*0"))
					})
				}
			}

			Context("when 'delete-org' fails", testFailureCase(0))
			Context("when 'delete-quota' fails", testFailureCase(1))
		})

		Describe("timing out", func() {
			BeforeEach(func() {
				timeout = 2 * time.Second
			})

			testTimeoutCase := func(callIndex int) func() {
				return func() {
					BeforeEach(func() {
						fakeStarter.ToReturn[callIndex].SleepTime = 5
					})

					It("returns a ginkgo error", func() {
						failures := InterceptGomegaFailures(func() {
							testSpace.Destroy()
						})

						Expect(failures).To(HaveLen(1))
						Expect(failures[0]).To(MatchRegexp("Timed out after 2.*"))
					})
				}
			}

			Context("when 'cf delete-org' times out", testTimeoutCase(0))
			Context("when 'cf delete-quota' times out", testTimeoutCase(1))
		})
	})

	Describe("QuotaName", func() {

		var testSpace *TestSpace
		BeforeEach(func() {
			testSpace = nil
		})

		It("returns the quota name", func() {
			testSpace = NewBaseTestSpace("", "", "my-quota", "", false, false, 1*time.Second, nil)
			Expect(testSpace.QuotaName()).To(Equal("my-quota"))
		})

		Context("when the TestSpace is nil", func() {
			It("returns the empty string", func() {
				Expect(testSpace.QuotaName()).To(BeEmpty())
			})
		})

	})

	Describe("OrganizationName", func() {
		var testSpace *TestSpace
		BeforeEach(func() {
			testSpace = nil
		})

		It("returns the organization name", func() {
			testSpace = NewBaseTestSpace("", "my-org", "", "", false, false, 1*time.Second, nil)
			Expect(testSpace.OrganizationName()).To(Equal("my-org"))
		})

		Context("when the TestSpace is nil", func() {
			It("returns the empty string", func() {
				Expect(testSpace.OrganizationName()).To(BeEmpty())
			})
		})
	})

	Describe("SpaceName", func() {
		var testSpace *TestSpace
		BeforeEach(func() {
			testSpace = nil
		})

		It("returns the organization name", func() {
			testSpace = NewBaseTestSpace("my-space", "", "", "", false, false, 1*time.Second, nil)
			Expect(testSpace.SpaceName()).To(Equal("my-space"))
		})

		Context("when the TestSpace is nil", func() {
			It("returns the empty string", func() {
				Expect(testSpace.SpaceName()).To(BeEmpty())
			})
		})
	})
})
