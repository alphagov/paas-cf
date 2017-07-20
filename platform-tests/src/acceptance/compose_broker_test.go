package acceptance_test

import (
	"fmt"
	"io/ioutil"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Compose broker - MongoDB", func() {
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

	Context("creating a database instance", func() {
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

			pollForMongoDbCreationCompletion(dbInstanceName)

			fmt.Fprintf(GinkgoWriter, "Created MongoDB instance: %s\n", dbInstanceName)

			Expect(cf.Cf(
				"push", appName,
				"--no-start",
				"-b", config.GoBuildpackName,
				"-p", "../../example-apps/healthcheck",
				"-f", "../../example-apps/healthcheck/manifest.yml",
				"-d", config.AppsDomain,
			).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

			Expect(cf.Cf("bind-service", appName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		})

		AfterEach(func() {
			cf.Cf("delete", appName, "-f").Wait(DEFAULT_TIMEOUT)

			Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			// Poll until destruction is complete, otherwise the org cleanup (in AfterSuite) fails.
			pollForMongoDbDeletionCompletion(dbInstanceName)
		})

		It("is accessible from the healthcheck app", func() {
			By("allowing connections with TLS")
			resp, err := httpClient.Get(helpers.AppUri(appName, fmt.Sprintf("/db?service=%s&ssl=true", serviceName)))
			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))

			By("disallowing connections without TLS")
			resp, err = httpClient.Get(helpers.AppUri(appName, fmt.Sprintf("/db?service=%s&ssl=false", serviceName)))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(500), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			Expect(string(body)).To(ContainSubstring("no reachable servers"), "Connection without TLS did not report a connection error")
		})
	})
})

func pollForMongoDbCreationCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for MongoDb creation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("create succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForMongoDbDeletionCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for MongoDb destruction to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "services").Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).ShouldNot(Say(dbInstanceName))
	fmt.Fprint(GinkgoWriter, "done\n")
}
