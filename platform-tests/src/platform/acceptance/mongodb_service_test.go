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

var _ = Describe("MongoDB backing service", func() {
	const (
		serviceName  = "mongodb"
		testPlanName = "tiny"
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring("tiny"))
	})

	PContext("creating a database instance", func() {
		// Avoid creating additional tests in this block because this setup and
		// teardown is slow (several minutes).

		var (
			appName        string
			dbInstanceName string
		)
		BeforeEach(func() {
			appName = generator.PrefixedRandomName("CATS-APP-")
			dbInstanceName = generator.PrefixedRandomName("test-db-")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			pollForServiceCreationCompletion(dbInstanceName)

			fmt.Fprintf(GinkgoWriter, "Created MongoDB instance: %s\n", dbInstanceName)

			Expect(cf.Cf(
				"push", appName,
				"--no-start",
				"-b", config.GoBuildpackName,
				"-p", "../../../example-apps/healthcheck",
				"-f", "../../../example-apps/healthcheck/manifest.yml",
				"-d", config.AppsDomain,
			).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

			Expect(cf.Cf("bind-service", appName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		})

		AfterEach(func() {
			cf.Cf("delete", appName, "-f").Wait(DEFAULT_TIMEOUT)

			Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			// Poll until destruction is complete, otherwise the org cleanup (in AfterSuite) fails.
			pollForServiceDeletionCompletion(dbInstanceName)
		})

		It("is accessible from the healthcheck app", func() {
			By("allowing connections with TLS")
			resp, err := httpClient.Get(helpers.AppUri(appName, "/mongo-test?ssl=true"))
			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))

			By("disallowing connections without TLS")
			resp, err = httpClient.Get(helpers.AppUri(appName, "/mongo-test?ssl=false"))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(500), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			Expect(string(body)).To(ContainSubstring("no reachable servers"), "Connection without TLS did not report a connection error")
		})
	})
})
