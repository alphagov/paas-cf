package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

var _ = Describe("A simple static app", func() {
	var (
		appName string
	)

	BeforeEach(func() {
		appName = generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"--no-start",
			"-b", config.StaticFileBuildpackName,
			"-p", "../../example_apps/static_app",
			"-d", config.AppsDomain,
		).Wait(DEFAULT_TIMEOUT)).To(Exit(0))
	})

	It("can be queried", func() {
		Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		Expect(helpers.CurlAppRoot(appName)).To(ContainSubstring("Hello World"))
	})
})
