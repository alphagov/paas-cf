package acceptance_test

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	gbytes "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

const (
	useLogCache = true
)

var _ = Describe("Logging pipeline", func() {
	var (
		appName string
	)

	BeforeEach(func() {
		appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP-LOGGING")
		Expect(cf.Cf(
			"push", appName,
			"-b", testConfig.GetGoBuildpackName(),
			"-p", "../example-apps/logging-pipeline",
			"-f", "../example-apps/logging-pipeline/manifest.yml",
			"-d", testConfig.GetAppsDomain(),
			"-i", "1",
			"-m", "64M",
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		Eventually(func() string {
			return helpers.CurlApp(testConfig, appName, "/")
		}, "15s", "5s").Should(ContainSubstring("Current time:"))
	})

	AfterEach(func() {
		Expect(cf.Cf("delete", appName, "-f", "-r").Wait("15s")).To(Exit(0))
	})

	Context("Application logs (diego)", func() {
		It("logs web process logs", func() {
			Eventually(func() *Session {
				appLogs := cf.Cf("logs", "--recent", appName)
				Expect(appLogs.Wait("30s")).To(Exit(0))
				return appLogs
			}, "2m", "10s").Should(gbytes.Say("APP[/]PROC[/]WEB[/]"))
		})
	})

	Context("Router logs (gorouter)", func() {
		It("logs routed requests", func() {
			Eventually(func() *Session {
				appLogs := cf.Cf("logs", "--recent", appName)
				Expect(appLogs.Wait("30s")).To(Exit(0))
				return appLogs
			}, "2m", "10s").Should(gbytes.Say("RTR[/]"))
		})
	})
})
