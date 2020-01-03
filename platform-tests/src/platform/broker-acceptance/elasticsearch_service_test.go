package acceptance_test

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"strings"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"

	prom "github.com/prometheus/client_golang/api"
	promv1 "github.com/prometheus/client_golang/api/prometheus/v1"
	prommodel "github.com/prometheus/common/model"
)

var _ = Describe("Elasticsearch backing service", func() {
	const (
		serviceName  = "elasticsearch"
		testPlanName = "tiny-6.x"
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		expectedPlans := []string{"tiny-6.x", "small-ha-6.x", "medium-ha-6.x", "large-ha-6.x"}

		actualPlans := cf.Cf("marketplace", "-s", serviceName).Wait(testConfig.DefaultTimeoutDuration())
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
			dbInstanceGUID string
		)
		BeforeEach(func() {
			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			dbInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-es")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			serviceGUIDSession := cf.Cf("service", dbInstanceName, "--guid")
			Expect(serviceGUIDSession.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
			dbInstanceGUID = strings.TrimSpace(string(serviceGUIDSession.Out.Contents()))

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

			By("checking that metrics are being scraped")
			prometheusURL := fmt.Sprintf("https://prometheus.%s", systemDomain)
			promClient, err := prom.NewClient(prom.Config{
				Address: prometheusURL,
				RoundTripper: basicAuthRoundTripper{
					username: prometheusBasicAuthUsername,
					password: prometheusBasicAuthPassword,
				},
			})
			Expect(err).NotTo(HaveOccurred())
			promv1API := promv1.NewAPI(promClient)
			By("querying prometheus")
			Eventually(func() int {
				ctx, cancelP := context.WithTimeout(context.Background(), 10*time.Second)
				defer cancelP()
				query := fmt.Sprintf(`up{aiven_service_name=~".*-%s"}`, dbInstanceGUID)
				result, warnings, err := promv1API.Query(ctx, query, time.Now())
				if err != nil {
					log.Printf("Encountered error querying prometheus: %s", err)
					return -1
				}
				if len(warnings) > 0 {
					log.Printf("Encountered warnings querying prometheus: %s", warnings)
					return -1
				}
				vector := result.(prommodel.Vector)
				if len(vector) == 0 {
					log.Printf("No results from Prometheus")
					return -1
				}
				return int(vector[0].Value)
			}, "5m", "10s").Should(BeNumerically(">=", 1))
		})
	})
})
