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

type Headers struct {
	X_Forwarded_For   []string `json:"X-Forwarded-For"`
	X_Forwarded_Proto []string `json:"X-Forwarded-Proto"`
}

var _ = PDescribe("X-Forwarded headers", func() {
	var headers Headers

	var _ = BeforeEach(func() {
		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"-b", config.GoBuildpackName,
			"-p", "../../example_apps/print_request_headers",
			"-d", config.AppsDomain,
			"-c", "./bin/debug_app; sleep 1; echo 'done'",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		jsonData := helpers.CurlAppRoot(appName)
		headers = Headers{}

		err := json.Unmarshal([]byte(jsonData), &headers)
		Expect(err).NotTo(HaveOccurred())
	})

	It("should have an upstream IP that is not on our network", func() {
		Expect(headers.X_Forwarded_For).Should(HaveLen(1))

		remoteIP := strings.Split(headers.X_Forwarded_For[0], ",")[0]
		parsedRemoteIP := net.ParseIP(remoteIP)
		_, infra_cidr, _ := net.ParseCIDR("10.0.0.0/8")

		Expect(infra_cidr.Contains(parsedRemoteIP)).To(BeFalse())
	})

	It("should indicate that the user connection was encrypted", func() {
		Expect(headers.X_Forwarded_Proto).Should(HaveLen(1))
		Expect(headers.X_Forwarded_Proto[0]).To(Equal("https"))
	})

})
