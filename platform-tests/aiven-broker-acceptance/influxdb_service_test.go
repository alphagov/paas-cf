package aiven_broker_acceptance_test

import (
	"fmt"
	"io/ioutil"

	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/generator"
	"github.com/cloudfoundry/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("InfluxDB backing service", func() {
	const (
		serviceName  = "influxdb"
		testPlanName = "tiny-1.x"
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		expectedPlans := []string{"tiny-1.x"}

		actualPlans := cf.Cf("marketplace", "-e", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(actualPlans).To(Exit(0))
		for _, plan := range expectedPlans {
			Expect(actualPlans.Out.Contents()).To(ContainSubstring(plan))
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
			dbInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-influxdb")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			pollForServiceCreationCompletion(dbInstanceName)

			fmt.Fprintf(GinkgoWriter, "Created InfluxDB instance: %s\n", dbInstanceName)

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

		It("is accessible from the healthcheck app", func() {
			resp, err := httpClient.Get(
				helpers.AppUri(appName, "/influxdb-test", testConfig),
			)

			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			resp.Body.Close()

			Expect(resp.StatusCode).To(
				Equal(200),
				"Got %d response from healthcheck app. Response body:\n%s\n",
				resp.StatusCode,
				string(body),
			)
		})
	})
})
