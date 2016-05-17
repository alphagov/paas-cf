package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	"encoding/json"
	"net"
	"strings"
)

var _ = Describe("X-Forwarded headers", func() {
	var headers struct {
		X_Forwarded_For []string `json:"X-Forwarded-For"`
	}

	var _ = BeforeEach(func() {
		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"-b", config.GoBuildpackName,
			"-p", "../../example-apps/print_request_headers",
			"-d", config.AppsDomain,
			"-c", "./bin/debug_app; sleep 1; echo 'done'",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		curlArgs := []string{"-f", "-H", "X-Forwarded-For: 1.2.3.4"}
		jsonData := helpers.CurlApp(appName, "/", curlArgs...)

		err := json.Unmarshal([]byte(jsonData), &headers)
		Expect(err).NotTo(HaveOccurred())
	})

	It("should have an upstream IP that is not on our network", func() {
		Expect(headers.X_Forwarded_For).Should(HaveLen(1))
		remoteIP := strings.Split(headers.X_Forwarded_For[0], ",")[1]

		parsedRemoteIP := net.ParseIP(strings.TrimSpace(remoteIP))

		Expect(parsedRemoteIP).ToNot(BeNil())

		_, infra_cidr, _ := net.ParseCIDR("10.0.0.0/8")

		Expect(infra_cidr.Contains(parsedRemoteIP)).To(BeFalse())
	})

	It("should append to existing X-Forwarded-For header", func() {
		Expect(headers.X_Forwarded_For).Should(HaveLen(1))

		remoteIP := strings.Split(headers.X_Forwarded_For[0], ",")[0]
		parsedRemoteIP := net.ParseIP(remoteIP)

		Expect(parsedRemoteIP).ToNot(BeNil())

		Expect(parsedRemoteIP).To(Equal(net.ParseIP("1.2.3.4")))
	})

})
