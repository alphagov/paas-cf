package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
)

var _ = Describe("PythonBuildpack", func() {
	var (
		appName string
	)

	It("should not fail when pushing a python app without Procfile", func() {
		appName = generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"--no-start",
			"-m", DEFAULT_MEMORY_LIMIT,
			"-p", "../../example-apps/simple-python-app",
			"-b", "python_buildpack",
			"-c", "python hello.py",
			"-d", config.AppsDomain,
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
	})

})
