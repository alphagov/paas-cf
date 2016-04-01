package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"

	"net"
	"time"
)

var _ = Describe("Http is closed", func() {

	var (
		CONNECTION_TIMEOUT = 11 * time.Second
	)

	It("for apps", func() {
		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"--no-start",
			"-b", config.StaticFileBuildpackName,
			"-p", "../../apps/static_app",
			"-d", config.AppsDomain,
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		Expect(cf.Cf("start", appName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

		uri := appName + "." + config.AppsDomain + ":80"
		_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
		Expect(err.(net.Error).Timeout()).To(BeTrue())
	})

	It("for api", func() {
		uri := "api." + config.SystemDomain + ":80"
		_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
		Expect(err.(net.Error).Timeout()).To(BeTrue())

	})

})
