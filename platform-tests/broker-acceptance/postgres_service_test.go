package broker_acceptance_test

import (
	"fmt"
	"io/ioutil"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Postgres backing service", func() {
	const (
		serviceName  = "postgres"
		testPlanName = "tiny-unencrypted-12"
	)

	It("should have registered the postgres service", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has only the expected plans available to the user", func() {
		workflowhelpers.AsUser(testContext.RegularUserContext(), testContext.ShortTimeout(), func() {
			plans := cf.Cf("marketplace", "-e", serviceName).Wait(testConfig.DefaultTimeoutDuration())
			Expect(plans).To(Exit(0))
			cfMarketplaceOutput := string(plans.Out.Contents())

			Expect(cfMarketplaceOutput).To(ContainSubstring("tiny-unencrypted-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-ha-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-ha-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-10-old"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-10-old"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-ha-10"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("tiny-unencrypted-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-ha-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-ha-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-10-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-ha-10-high-iops"))

			Expect(cfMarketplaceOutput).To(ContainSubstring("tiny-unencrypted-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-ha-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-ha-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-11-old"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-11-old"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-ha-11"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("tiny-unencrypted-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-ha-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-ha-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-11-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-ha-11-high-iops"))

			Expect(cfMarketplaceOutput).To(ContainSubstring("tiny-unencrypted-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-ha-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-ha-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-12-old"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-12-old"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-ha-12"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("tiny-unencrypted-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("small-ha-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("medium-ha-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("large-ha-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-12-high-iops"))
			Expect(cfMarketplaceOutput).To(ContainSubstring("xlarge-ha-12-high-iops"))

		})
	})
	Context("creating a database instance", func() {
		// Avoid creating additional tests in this block because this setup and
		// teardown is slow (several minutes).

		var (
			appName        string
			dbInstanceName string
		)
		BeforeEach(func() {
			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			dbInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-db")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			pollForServiceCreationCompletion(dbInstanceName)

			fmt.Fprintf(GinkgoWriter, "Created database instance: %s\n", dbInstanceName)

			Expect(cf.Cf(
				"push", appName,
				"--no-start",
				"-b", testConfig.GetGoBuildpackName(),
				"-p", "../example-apps/healthcheck",
				"-f", "../example-apps/healthcheck/manifest.yml",
			).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

			Expect(cf.Cf("bind-service", appName, dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		})

		AfterEach(func() {
			cf.Cf("delete", appName, "-f").Wait(testConfig.DefaultTimeoutDuration())

			Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			// Poll until destruction is complete, otherwise the org cleanup (in AfterSuite) fails.
			pollForServiceDeletionCompletion(dbInstanceName)
		})

		It("binds a DB instance to the Healthcheck app that matches our criteria", func() {
			By("allowing connections from the Healthcheck app")
			resp, err := httpClient.Get(helpers.AppUri(appName, fmt.Sprintf("/db?service=%s", serviceName), testConfig))
			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))

			By("disallowing connections from the Healthcheck app without TLS")
			resp, err = httpClient.Get(helpers.AppUri(appName, fmt.Sprintf("/db?service=%s&ssl=false", serviceName), testConfig))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).NotTo(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			Expect(body).To(MatchRegexp("no pg_hba.conf entry for .* SSL off"), "Connection without TLS did not report a TLS error")
		})
	})
})
