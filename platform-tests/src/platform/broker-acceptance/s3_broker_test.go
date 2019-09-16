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

var _ = Describe("S3 broker", func() {
	const (
		serviceName  = "aws-s3-bucket"
		testPlanName = "default"
	)

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring("default"))
	})

	Context("creating an S3 bucket", func() {
		var (
			appName             string
			serviceInstanceName string
		)

		It("is accessible from the healthcheck app", func() {

			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-s3-bucket")

			By("creating the service: "+serviceInstanceName, func() {
				Expect(cf.Cf("create-service", serviceName, testPlanName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceCreationCompletion(serviceInstanceName)
			})

			defer By("deleting the service", func() {
				Expect(cf.Cf("delete-service", serviceInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
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
				Expect(cf.Cf("bind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
			})

			By("starting the app", func() {
				Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			By("testing the S3 bucket access from the app", func() {
				resp, err := httpClient.Get(helpers.AppUri(appName, "/s3-test", testConfig))
				Expect(err).NotTo(HaveOccurred())
				body, err := ioutil.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			})

		})
	})

	Context("multiple operations against a single bucket", func(){
		var (
			appOneName          string
			appTwoName          string
			serviceInstanceName string
		)

		It("do not run in to race conditions", func(){
			appOneName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			appTwoName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-s3-bucket")

			By("creating the service: " + serviceInstanceName, func() {
				Expect(
					cf.
						Cf("create-service", serviceName, testPlanName, serviceInstanceName).
						Wait(testConfig.DefaultTimeoutDuration()),
				).
				To(Exit(0))
				pollForServiceCreationCompletion(serviceInstanceName)
			})

			defer By("deleting the service", func() {
				Expect(
					cf.Cf("delete-service", serviceInstanceName, "-f").
						Wait(testConfig.DefaultTimeoutDuration()),
				).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})

			By("deploying a first app", func() {
				Expect(cf.Cf(
					"push", appOneName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../../../example-apps/healthcheck",
					"-f", "../../../example-apps/healthcheck/manifest.yml",
					"-d", testConfig.GetAppsDomain(),
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})
			defer By("deleting the first app", func() {
				cf.Cf("delete", appOneName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("deploying a second app", func() {
				Expect(cf.Cf(
					"push", appOneName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../../../example-apps/healthcheck",
					"-f", "../../../example-apps/healthcheck/manifest.yml",
					"-d", testConfig.GetAppsDomain(),
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})
			defer By("deleting the second app", func() {
				cf.Cf("delete", appTwoName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("binding and unbinding the two apps simultaneously, we should see no errors", func(){
				// Prepare four channels
				bindAppOneChan := make(chan int)
				bindAppTwoChan := make(chan int)
				unbindAppOneChan := make(chan int)
				unbindAppTwoChan := make(chan int)

				// Concurrently (as possible) bind and unbind the services
				bindServiceToAppAsync(appOneName, serviceInstanceName, bindAppOneChan)
				bindServiceToAppAsync(appTwoName, serviceInstanceName, bindAppTwoChan)
				unbindServiceFromAppAsync(appOneName, serviceInstanceName, unbindAppOneChan)
				unbindServiceFromAppAsync(appTwoName, serviceInstanceName, unbindAppTwoChan)

				// Check that every channel exited 0 (ie didn't error)
				Eventually(func() int {
					return <-bindAppOneChan
				}).Should(Equal(0))

				Eventually(func() int {
					return <-bindAppTwoChan
				}).Should(Equal(0))

				Eventually(func() int {
					return <-unbindAppOneChan
				}).Should(Equal(0))

				Eventually(func() int {
					return <-unbindAppTwoChan
				}).Should(Equal(0))
			})
		})
	})
})

func bindServiceToAppAsync(appName string, serviceInstanceName string, outChan chan<- int) {
	go (func() {
		session := cf.Cf("bind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		exitCode := session.ExitCode()

		outChan <- exitCode
	})()
}

func unbindServiceFromAppAsync(appName string, serviceInstanceName string, outChan chan<- int) {
	go (func() {
		session := cf.Cf("unbind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		exitCode := session.ExitCode()

		outChan <- exitCode
	})()
}
