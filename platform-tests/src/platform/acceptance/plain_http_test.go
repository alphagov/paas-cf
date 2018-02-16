package acceptance_test

import (
	"encoding/json"
	"fmt"
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

	Describe("to the API", func() {
		It("has the connection refused", func() {
			req, err := http.NewRequest("GET", fmt.Sprintf("http://%s/v2/info", testConfig.ApiEndpoint), nil)
			Expect(err).NotTo(HaveOccurred())
			_, err = http.DefaultTransport.RoundTrip(req)
			Expect(err).To(HaveOccurred())
			Expect(err).To(MatchError(Or(
				ContainSubstring("connection refused"),
				ContainSubstring("connection reset by peer"),
			)))
		})
	})

	Describe("to UAA", func() {
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

		It("is redirected to the https endpoint", func() {
			req, err := http.NewRequest("GET", fmt.Sprintf("http://%s/", uaaDomain), nil)
			Expect(err).NotTo(HaveOccurred())
			resp, err := http.DefaultTransport.RoundTrip(req)
			Expect(err).NotTo(HaveOccurred())

			Expect(resp.StatusCode).To(Equal(301))
			Expect(resp.Header.Get("Location")).To(Equal(fmt.Sprintf("https://%s/", uaaDomain)))
		})

		It("has any path and query components removed when redirecting", func() {
			req, err := http.NewRequest("GET", fmt.Sprintf("http://%s/oauth/token", uaaDomain), nil)
			Expect(err).NotTo(HaveOccurred())
			resp, err := http.DefaultTransport.RoundTrip(req)
			Expect(err).NotTo(HaveOccurred())

			Expect(resp.StatusCode).To(Equal(301))
			Expect(resp.Header.Get("Location")).To(Equal(fmt.Sprintf("https://%s/", uaaDomain)))
		})
	})

	Describe("to an app", func() {
		It("is redirected to the https endpoint", func() {
			req, err := http.NewRequest("GET", fmt.Sprintf("http://foo.%s/", testConfig.AppsDomain), nil)
			Expect(err).NotTo(HaveOccurred())
			resp, err := http.DefaultTransport.RoundTrip(req)
			Expect(err).NotTo(HaveOccurred())

			Expect(resp.StatusCode).To(Equal(301))
			Expect(resp.Header.Get("Location")).To(Equal(fmt.Sprintf("https://foo.%s/", testConfig.AppsDomain)))

			By("does not include an HSTS header")
			// See https://tools.ietf.org/html/rfc6797#section-7.2
			Expect(resp.Header.Get("Strict-Transport-Security")).To(BeEmpty())
		})

		It("has any path and query components removed when redirecting", func() {
			req, err := http.NewRequest("GET", fmt.Sprintf("http://foo.%s/bar?baz=qux", testConfig.AppsDomain), nil)
			Expect(err).NotTo(HaveOccurred())
			resp, err := http.DefaultTransport.RoundTrip(req)
			Expect(err).NotTo(HaveOccurred())

			Expect(resp.StatusCode).To(Equal(301))
			Expect(resp.Header.Get("Location")).To(Equal(fmt.Sprintf("https://foo.%s/", testConfig.AppsDomain)))
		})
	})
})
