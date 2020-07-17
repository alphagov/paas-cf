package acceptance_test

import (
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

const (
	EXTENDED_PUSH_TIMEOUT = 360 * time.Second
	STAGING_DELAY         = "300"
)

var _ = Describe("cf push", func() {
	var appName string

	Context("when staging an app takes a long time", func() {
		BeforeEach(func() {
			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "SLEEPY-APP")
			Expect(cf.Cf(
				"push", appName,
				"-b", "https://github.com/alphagov/paas-cf-sleepy-buildpack",
				// The contents of this directory are pushed, but not served
				// See the buildpack for details.
				"-p", "../example-apps/static-app/",
				"-d", testConfig.GetAppsDomain(),
				"--no-start",
				"--no-manifest",
			).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

			Expect(cf.Cf(
				"set-env", appName,
				"SLEEPY_TIME", STAGING_DELAY,
			).Wait(30 * time.Second)).To(Exit(0))
		})

		It("should start the app successfully", func() {
			Expect(cf.Cf("start", appName).Wait(EXTENDED_PUSH_TIMEOUT)).To(Exit(0))
			response := helpers.CurlApp(testConfig, appName, "/")
			Expect(response).To(BeEquivalentTo("OK"))
		})
	})
})
