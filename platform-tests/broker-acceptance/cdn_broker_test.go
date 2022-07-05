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

			// best effort tidyup - we don't really care if these pass or fail
			defer pollForServiceDeletionCompletion(serviceInstanceName)
			defer cf.Cf("delete-domain", domainName, "-f")
			defer cf.Cf("delete-service", serviceInstanceName, "-f")

			By("creating a CDN instance: "+serviceInstanceName, func() {
				Expect(cf.Cf("create-domain", orgName, domainName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				Expect(cf.Cf("create-service", serviceName, serviceName, serviceInstanceName, "-c", domainNameList).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForCdnServiceCreationCompletion(serviceInstanceName)
			})

			By("deleting a standard CDN service", func() {
				Expect(cf.Cf("delete-service", serviceInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				Expect(cf.Cf("delete-domain", domainName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})
		})

		It("can create a CDN when we cf create-domain a parent domain", func() {

			orgName := testContext.TestSpace.OrganizationName()
			parentDomainName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "cdn-broker") + ".net"
			domainName := "foo.bar." + parentDomainName
			domainNameList := fmt.Sprintf(`{"domain": "%s"}`, domainName)

			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-cdn")

			// best effort tidyup - we don't really care if these pass or fail
			defer pollForServiceDeletionCompletion(serviceInstanceName)
			defer cf.Cf("delete-domain", parentDomainName, "-f")
			defer cf.Cf("delete-service", serviceInstanceName, "-f")

			By("creating a CDN instance: "+serviceInstanceName, func() {
				Expect(cf.Cf("create-domain", orgName, parentDomainName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				Expect(cf.Cf("create-service", serviceName, serviceName, serviceInstanceName, "-c", domainNameList).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForCdnServiceCreationCompletion(serviceInstanceName)
			})

			By("deleting a standard CDN service", func() {
				Expect(cf.Cf("delete-service", serviceInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				Expect(cf.Cf("delete-domain", parentDomainName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})
		})

		It("refuses to create a CDN for a domain without a cf create-domain", func() {
			domainName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "cdn-broker") + ".net"
			domainNameList := fmt.Sprintf(`{"domain": "%s"}`, domainName)

			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-cdn")

			// best effort tidyup - we don't really care if these pass or fail.
			// currently this kind of failure doesn't actually stop the service
			// being "created".
			defer pollForServiceDeletionCompletion(serviceInstanceName)
			defer cf.Cf("delete-service", serviceInstanceName, "-f")

			By("attempting to create a CDN instance: "+serviceInstanceName, func() {
				cf_create_service := cf.Cf("create-service", serviceName, serviceName, serviceInstanceName, "-c", domainNameList).Wait(testConfig.DefaultTimeoutDuration())
				Expect(cf_create_service).To(Exit(1))
				Expect(cf_create_service.Err.Contents()).To(ContainSubstring("cf create-domain"))
			})
		})

		It("refuses to create a CDN for a domain with wrong ownership", func() {
			domainName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "cdn-broker") + ".net"
			domainNameList := fmt.Sprintf(`{"domain": "%s"}`, domainName)

			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-cdn")

			// best effort tidyup - we don't really care if these pass or fail.
			// currently this kind of failure doesn't actually stop the service
			// being "created".
			defer pollForServiceDeletionCompletion(serviceInstanceName)
			defer cf.Cf("delete-domain", domainName, "-f")
			defer cf.Cf("delete-service", serviceInstanceName, "-f")

			By("attempting to create a CDN instance: "+serviceInstanceName, func() {
				Expect(cf.Cf("create-domain", altOrgName, domainName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				cf_create_service := cf.Cf("create-service", serviceName, serviceName, serviceInstanceName, "-c", domainNameList).Wait(testConfig.DefaultTimeoutDuration())
				Expect(cf_create_service).To(Exit(1))
				Expect(cf_create_service.Err.Contents()).To(ContainSubstring("different organization"))
			})
		})

		// tests of update-service functionality would be wonderful but quite hard to implement as to get a service
		// into a state where it will accept updates we would have to first validate the domain which would require
		// the tests having permissions to update dns records on route53.

	})
})
