package acceptance_test

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("plain HTTP requests", func() {
	const (
		CONNECTION_TIMEOUT = 11 * time.Second
	)

	Context("to the system domain", func() {
		Describe("for the CC API", func() {
			It("has the connection refused", func() {
				uri := testConfig.GetApiEndpoint() + ":80"
				_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
				Expect(err).To(HaveOccurred(), "should not connect")
				Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
			})
		})

		Describe("for UAA", func() {
			var uaaDomain string

			BeforeEach(func() {
				infoCommand := cf.Cf("curl", "/v2/info")
				Expect(infoCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

				var infoResp struct {
					TokenEndpoint string `json:"token_endpoint"`
				}
				err := json.Unmarshal(infoCommand.Buffer().Contents(), &infoResp)
				Expect(err).NotTo(HaveOccurred())

				uaaHttpsURL, err := url.Parse(infoResp.TokenEndpoint)
				Expect(err).NotTo(HaveOccurred())
				uaaDomain = strings.Split(uaaHttpsURL.Host, ":")[0]
			})

			It("has the connection refused", func() {
				uri := uaaDomain + ":80"
				_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
				Expect(err).To(HaveOccurred(), "should not connect")
				Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
			})
		})

		Describe("for the product page", func() {
			It("has the connection refused", func() {
				systemDomain := GetConfigFromEnvironment("SYSTEM_DNS_ZONE_NAME")
				uri := fmt.Sprintf("www.%s:80", systemDomain)
				_, err := net.DialTimeout("tcp", uri, CONNECTION_TIMEOUT)
				Expect(err).To(HaveOccurred(), "should not connect")
				Expect(err.(net.Error).Timeout()).To(BeTrue(), "should timeout")
			})
		})
	})

	Context("to the apps domain", func() {
		Describe("for an app", func() {
			It("is redirected to the https endpoint", func() {
				req, err := http.NewRequest("GET", fmt.Sprintf("http://foo.%s/", testConfig.GetAppsDomain()), nil)
				Expect(err).NotTo(HaveOccurred())
				resp, err := http.DefaultTransport.RoundTrip(req)
				Expect(err).NotTo(HaveOccurred())

				Expect(resp.StatusCode).To(Equal(301))
				Expect(resp.Header.Get("Location")).To(
					Equal(fmt.Sprintf("https://foo.%s:443/", testConfig.GetAppsDomain())),
				)

				By("does not include an HSTS header")
				// See https://tools.ietf.org/html/rfc6797#section-7.2
				Expect(resp.Header.Get("Strict-Transport-Security")).To(BeEmpty())
			})

			It("has any path and query components removed when redirecting", func() {
				req, err := http.NewRequest("GET", fmt.Sprintf("http://foo.%s/bar?baz=qux", testConfig.GetAppsDomain()), nil)
				Expect(err).NotTo(HaveOccurred())
				resp, err := http.DefaultTransport.RoundTrip(req)
				Expect(err).NotTo(HaveOccurred())

				Expect(resp.StatusCode).To(Equal(301))
				Expect(resp.Header.Get("Location")).To(
					Equal(fmt.Sprintf("https://foo.%s:443/", testConfig.GetAppsDomain())),
				)
			})
		})
	})
})
