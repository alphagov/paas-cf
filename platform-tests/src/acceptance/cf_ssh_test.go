package acceptance_test

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("CF SSH", func() {
	It("should be enabled", func() {
		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"-b", config.StaticFileBuildpackName,
			"-p", "../../example-apps/static-app",
			"-d", config.AppsDomain,
			"-i", "1",
			"-m", "64M",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		cfSSH := cf.Cf("ssh", appName, "-c", "uptime").Wait(DEFAULT_TIMEOUT)
		Expect(cfSSH).To(Exit(0))
		Expect(cfSSH).To(Say("load average:"))
	})
})
