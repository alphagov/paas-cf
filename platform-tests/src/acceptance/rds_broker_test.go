package acceptance_test

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"regexp"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

const (
	DB_CREATE_TIMEOUT = 30 * time.Minute
)

var _ = Describe("RDS broker - Postgres", func() {
	const (
		serviceName  = "postgres"
		testPlanName = "Free"
	)

	It("should have registered the postgres service", func() {
		plans := cf.Cf("marketplace").Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring("Free"))
		Expect(plans.Out.Contents()).To(ContainSubstring("S-dedicated-9.5"))
		Expect(plans.Out.Contents()).To(ContainSubstring("S-HA-dedicated-9.5"))
		Expect(plans.Out.Contents()).To(ContainSubstring("M-dedicated-9.5"))
		Expect(plans.Out.Contents()).To(ContainSubstring("M-HA-dedicated-9.5"))
		Expect(plans.Out.Contents()).To(ContainSubstring("L-dedicated-9.5"))
		Expect(plans.Out.Contents()).To(ContainSubstring("L-HA-dedicated-9.5"))
	})

	Context("creating a database instance", func() {
		// Avoid creating additional tests in this block because this setup and
		// teardown is slow (several minutes).

		var (
			appName         string
			dbInstanceName  string
			rdsInstanceName string
		)
		BeforeEach(func() {
			appName = generator.PrefixedRandomName("CATS-APP-")
			dbInstanceName = generator.PrefixedRandomName("test-db-")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			pollForRDSCreationCompletion(dbInstanceName)

			rdsInstanceName = getRDSInstanceName(dbInstanceName)
			fmt.Fprintf(GinkgoWriter, "Created RDS instance: %s\n", rdsInstanceName)

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
			pollForRDSDeletionCompletion(dbInstanceName)
		})

		It("binds a DB instance to the Healthcheck app that matches our criteria", func() {
			By("allowing connections from the Healthcheck app")
			resp, err := httpClient.Get(helpers.AppUri(appName, "/db"))
			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))

			By("disallowing connections from the Healthcheck app without TLS")
			resp, err = httpClient.Get(helpers.AppUri(appName, "/db?ssl=false"))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).NotTo(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			Expect(body).To(MatchRegexp("no pg_hba.conf entry for .* SSL off"), "Connection without TLS did not report a TLS error")
		})
	})
})

var _ = Describe("RDS broker - MySQL", func() {
	const (
		serviceName  = "mysql"
		testPlanName = "Free"
	)

	It("should have registered the mysql service", func() {
		plans := cf.Cf("marketplace").Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring("Free"))
		Expect(plans.Out.Contents()).To(ContainSubstring("S-dedicated-5.7"))
		Expect(plans.Out.Contents()).To(ContainSubstring("S-HA-dedicated-5.7"))
		Expect(plans.Out.Contents()).To(ContainSubstring("M-dedicated-5.7"))
		Expect(plans.Out.Contents()).To(ContainSubstring("M-HA-dedicated-5.7"))
		Expect(plans.Out.Contents()).To(ContainSubstring("L-dedicated-5.7"))
		Expect(plans.Out.Contents()).To(ContainSubstring("L-HA-dedicated-5.7"))
	})

	Context("creating a database instance", func() {
		// Avoid creating additional tests in this block because this setup and teardown is
		// slow (several minutes).

		var (
			appName         string
			dbInstanceName  string
			rdsInstanceName string
		)
		BeforeEach(func() {
			appName = generator.PrefixedRandomName("CATS-APP-")
			dbInstanceName = generator.PrefixedRandomName("test-db-")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			pollForRDSCreationCompletion(dbInstanceName)

			rdsInstanceName = getRDSInstanceName(dbInstanceName)
			fmt.Fprintf(GinkgoWriter, "Created RDS instance: %s\n", rdsInstanceName)

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
			pollForRDSDeletionCompletion(dbInstanceName)
		})

		It("binds a DB instance to the Healthcheck app that matches our criteria", func() {
			By("allowing connections from the Healthcheck app")
			resp, err := httpClient.Get(helpers.AppUri(appName, "/db?service=mysql"))
			Expect(err).NotTo(HaveOccurred(), "Couldn't get the correct response")
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred(), "Couldn't read the correct body")
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
		})
	})
})

func pollForRDSCreationCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for RDS creation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("create succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForRDSDeletionCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for RDS destruction to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "services").Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).ShouldNot(Say(dbInstanceName))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func getRDSInstanceName(dbInstanceName string) string {
	serviceOutput := cf.Cf("service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
	Expect(serviceOutput).To(Exit(0))
	rxp, _ := regexp.Compile("rdsbroker-([a-z0-9-]+)")
	return string(rxp.Find(serviceOutput.Out.Contents()))
}

// quietCf is an equivelent of cf.Cf that doesn't send the output to
// GinkgoWriter. Used when you don't want the output, even in verbose mode (eg
// when polling the API)
func quietCf(program string, args ...string) *Session {
	command, err := Start(exec.Command(program, args...), nil, nil)
	Expect(err).NotTo(HaveOccurred())
	return command
}
