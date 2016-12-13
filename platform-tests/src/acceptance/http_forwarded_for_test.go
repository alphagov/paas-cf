package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"strings"
)

var _ = Describe("X-Forwarded headers", func() {
	const (
		egressURL   = "https://canhazip.com/"
		fakeProxyIP = "1.2.3.4"
	)

	var (
		egressIP string
		headers  struct {
			X_Forwarded_For []string `json:"X-Forwarded-For"`
		}
	)

	BeforeEach(func() {
		resp, err := http.Get(egressURL)
		Expect(err).ToNot(HaveOccurred(), "Unable to get egress IP from %s", egressURL)
		defer resp.Body.Close()

		body, err := ioutil.ReadAll(resp.Body)
		Expect(err).ToNot(HaveOccurred())
		egressIP = strings.TrimSpace(fmt.Sprintf("%s", body))
		Expect(net.ParseIP(egressIP)).ToNot(BeNil(), "Unable to parse egress IP from %s: %s", egressURL, egressIP)

		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"-b", config.GoBuildpackName,
			"-p", "../../example-apps/print_request_headers",
			"-d", config.AppsDomain,
			"-c", "./bin/debug_app; sleep 1; echo 'done'",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		curlArgs := []string{"-f", "-H", fmt.Sprintf("X-Forwarded-For: %s", fakeProxyIP)}
		jsonData := helpers.CurlApp(appName, "/", curlArgs...)

		err = json.Unmarshal([]byte(jsonData), &headers)
		Expect(err).NotTo(HaveOccurred())
	})

	It("should append real egress IP to existing X-Forwarded-For request header", func() {
		Expect(headers.X_Forwarded_For).To(HaveLen(1))

		xffNoWhitespace := strings.Replace(headers.X_Forwarded_For[0], " ", "", -1)
		xffIPs := strings.Split(xffNoWhitespace, ",")

		Expect(xffIPs).To(ConsistOf(
			fakeProxyIP,
			egressIP,
			"127.0.0.1", // FIXME: haproxy -> gorouter, undesirable.
		))
	})
})
