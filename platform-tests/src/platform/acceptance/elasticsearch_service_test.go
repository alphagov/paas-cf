package acceptance_test

import (
	"fmt"
	"io/ioutil"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Elasticsearch backing service", func() {
	const (
		serviceName = "elasticsearch"
	)

	var (
		planNames = []string{"tiny-5.x", "tiny-6.x", "small-ha-5.x", "small-ha-6.x"}
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		for _, planName := range planNames {
			Expect(plans.Out.Contents()).To(ContainSubstring(planName))
		}
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
			dbInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-es")
			Expect(cf.Cf("create-service", serviceName, planNames[0], dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			pollForServiceCreationCompletion(dbInstanceName)

			fmt.Fprintf(GinkgoWriter, "Created Elasticsearch instance: %s\n", dbInstanceName)

			Expect(cf.Cf(
				"push", appName,
				"--no-start",
				"-b", testConfig.GetGoBuildpackName(),
				"-p", "../../../example-apps/healthcheck",
				"-f", "../../../example-apps/healthcheck/manifest.yml",
				"-d", testConfig.GetAppsDomain(),
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

		It("is accessible from the healthcheck app", func() {
			By("allowing connections with TLS")
			resp, err := httpClient.Get(helpers.AppUri(appName, "/elasticsearch-test", testConfig))
			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))

			By("disallowing connections without TLS")
			resp, err = httpClient.Get(helpers.AppUri(appName, "/elasticsearch-test?tls=false", testConfig))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			resp.Body.Close()
			Expect(resp.StatusCode).To(Equal(500), "Expected 500, got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			Expect(string(body)).To(ContainSubstring("EOF"), "Connection without TLS did not report a connection error")
		})
	})
})
