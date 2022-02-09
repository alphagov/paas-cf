package broker_acceptance_test

import (
	"fmt"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("CDN broker", func() {
	const (
		serviceName = "cdn-route"
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-e", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring(serviceName))
	})

	Context("creating a CDN", func() {
		var (
			serviceInstanceName string
		)

		It("can create a CDN", func() {

			orgName := testContext.TestSpace.OrganizationName()
			domainName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "cdn-broker") + ".net"
			domainNameList := fmt.Sprintf(`{"domain": "%s"}`, domainName)

			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-cdn")

			By("creating a CDN instance: "+serviceInstanceName, func() {
				Expect(cf.Cf("create-domain", orgName, domainName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				Expect(cf.Cf("create-service", serviceName, serviceName, serviceInstanceName, "-c", domainNameList).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForCdnServiceCreationCompletion(serviceInstanceName)
			})

			defer By("deleting a standard CDN service", func() {
				Expect(cf.Cf("delete-service", serviceInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				Expect(cf.Cf("delete-domain", domainName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})
		})
	})
})
