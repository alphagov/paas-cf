package acceptance_test

import (
	"io/ioutil"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Redis backing service", func() {
	const (
		serviceName  = "redis"
		testPlanName = "tiny-clustered-3.2"
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring("tiny"))
	})

	Context("creating a database instance", func() {
		// Avoid creating additional tests in this block because this setup and
		// teardown is slow (several minutes).

		var (
			appName        string
			dbInstanceName string
		)

		It("is accessible from the healthcheck app", func() {

			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			dbInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-redis")

			By("creating the service: "+dbInstanceName, func() {
				Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName, "-c", `{"maxmemory_policy": "noeviction"}`).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceCreationCompletion(dbInstanceName)
			})

			defer By("deleting the service", func() {
				Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceDeletionCompletion(dbInstanceName)
			})

			By("updating the service: "+dbInstanceName, func() {
				Expect(cf.Cf("update-service", dbInstanceName, "-c", `{"maxmemory_policy": "volatile-ttl"}`).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceUpdateCompletion(dbInstanceName)
			})

			By("pushing the healthcheck app", func() {
				Expect(cf.Cf(
					"push", appName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../../../example-apps/healthcheck",
					"-f", "../../../example-apps/healthcheck/manifest.yml",
					"-d", testConfig.GetAppsDomain(),
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			defer By("deleting the app", func() {
				cf.Cf("delete", appName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("binding the service", func() {
				Expect(cf.Cf("bind-service", appName, dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
			})

			By("starting the app", func() {
				Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			By("allowing connections with TLS", func() {
				resp, err := httpClient.Get(helpers.AppUri(appName, "/redis-test", testConfig))
				Expect(err).NotTo(HaveOccurred())
				body, err := ioutil.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			})

		})
	})
})
