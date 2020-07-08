package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	"github.com/hashicorp/go-retryablehttp"

	"encoding/json"
	"fmt"
	"io/ioutil"
	"net"
	"strings"
)

var _ = Describe("X-Forwarded headers", func() {
	const (
		egressURL   = "https://icanhazip.com/"
		fakeProxyIP = "1.2.3.4"
	)

	var (
		egressIP string
		headers  struct {
			X_Forwarded_For []string `json:"X-Forwarded-For"`
		}
	)

	BeforeEach(func() {
		resp, err := retryablehttp.Get(egressURL)
		Expect(err).ToNot(HaveOccurred(), "Unable to get egress IP from %s", egressURL)
		defer resp.Body.Close()

		body, err := ioutil.ReadAll(resp.Body)
		Expect(err).ToNot(HaveOccurred())
		egressIP = strings.TrimSpace(fmt.Sprintf("%s", body))
		Expect(net.ParseIP(egressIP)).ToNot(BeNil(), "Unable to parse egress IP from %s: %s", egressURL, egressIP)

		appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"-p", "../example-apps/http_tester",
			"-f", "../example-apps/http_tester/manifest.yml",
			"-d", testConfig.GetAppsDomain(),
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

		curlArgs := []string{"-f", "-H", fmt.Sprintf("X-Forwarded-For: %s", fakeProxyIP)}
		jsonData := helpers.CurlApp(testConfig, appName, "/print-headers", curlArgs...)

		err = json.Unmarshal([]byte(jsonData), &headers)
		Expect(err).NotTo(HaveOccurred())
	})

	It("should append real egress IP to existing X-Forwarded-For request header", func() {
		Expect(headers.X_Forwarded_For).To(HaveLen(1))

		xffNoWhitespace := strings.Replace(headers.X_Forwarded_For[0], " ", "", -1)
		xffIPs := strings.Split(xffNoWhitespace, ",")

		var loadBalancerIP string
		for _, v := range xffIPs {
			if strings.HasPrefix(v, "10") {
				loadBalancerIP = v
			}
		}

		Expect(loadBalancerIP).NotTo(
			Equal(""), "There should be an internal IP in the header",
		)

		cidr := "10.0.0.0/8"
		_, ipnet, _ := net.ParseCIDR(cidr)

		Expect(xffIPs).Should(ContainElement(fakeProxyIP))
		Expect(xffIPs).Should(ContainElement(egressIP))
		Expect(ipnet.Contains(net.ParseIP(loadBalancerIP))).To(Equal(true))
	})
})
