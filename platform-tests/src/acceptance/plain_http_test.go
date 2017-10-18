package acceptance_test

import (
	"net"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
)

var _ = Describe("plain HTTP requests", func() {
	const (
		CONNECTION_TIMEOUT = 11 * time.Second
	)

	Describe("to the API", func() {
		It("has the connection refused", func() {
			uri := config.ApiEndpoint + ":80"
			_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
			Expect(err).To(HaveOccurred(), "should not connect")
			Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
		})
	})

	Describe("to an app", func() {
		It("has the connection refused", func() {
			appName := generator.PrefixedRandomName("CATS-APP-")
			Expect(cf.Cf(
				"push", appName,
				"-b", config.StaticFileBuildpackName,
				"-p", "../../example-apps/static-app",
				"-d", config.AppsDomain,
			).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

			uri := appName + "." + config.AppsDomain + ":80"
			_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
			Expect(err).To(HaveOccurred(), "should not connect")
			Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
		})
	})
})
