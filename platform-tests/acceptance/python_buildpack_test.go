package acceptance_test

import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/generator"
)

var _ = Describe("PythonBuildpack", func() {
	var (
		appName string
	)

	XIt("should not fail when pushing a python app without Procfile", func() {
		appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"--no-start",
			"-m", DEFAULT_MEMORY_LIMIT,
			"-p", "../example-apps/simple-python-app",
			"-b", "python_buildpack",
			"-c", "python hello.py",
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
	})

})
