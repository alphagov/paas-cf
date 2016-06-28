package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
)

var _ = Describe("CustomBuildpacks", func() {
	var (
		appName string
	)

	It("should fail when using a buildpack from a git url", func() {
		appName = generator.PrefixedRandomName("CATS-APP-")
		session := cf.Cf(
			"push", appName, "--no-start",
			"-m", DEFAULT_MEMORY_LIMIT,
			"-p", "../../example-apps/static-app",
			"-b", "https://github.com/cloudfoundry/staticfile-buildpack.git",
			"-d", config.AppsDomain,
		).Wait(DEFAULT_TIMEOUT)
		Expect(session).To(Exit(1))
		Expect(session.Out.Contents()).To(ContainSubstring("custom buildpacks are disabled"))
	})

})
