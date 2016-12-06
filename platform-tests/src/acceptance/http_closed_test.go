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

var _ = Describe("Http client", func() {

	var (
		CONNECTION_TIMEOUT = 11 * time.Second
	)

	It("that tries to connect to apps", func() {
		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"--no-start",
			"-b", config.StaticFileBuildpackName,
			"-p", "../../example-apps/static-app",
			"-d", config.AppsDomain,
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		uri := appName + "." + config.AppsDomain + ":80"
		_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
		Expect(err).ToNot(BeNil(), "should not connect")
		Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
	})

	It("that tries to connect to api", func() {
		uri := config.ApiEndpoint + ":80"
		_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
		Expect(err).ToNot(BeNil(), "should not connect")
		Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
	})

})
