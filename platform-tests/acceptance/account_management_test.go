package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"encoding/json"
	"io/ioutil"
	"net/http"
	"net/url"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
)

var _ = Describe("AccountManagement", func() {
	const email = "the-multi-cloud-paas-team+this-should-not-be-created@digital.cabinet-office.gov.uk"

	var (
		params   url.Values
		authURL  *url.URL
		tokenURL *url.URL
	)

	BeforeEach(func() {
		params = url.Values{}
		params.Set("client_id", "")
		params.Set("redirect_uri", "")

		infoCommand := cf.Cf("curl", "/v2/info")
		Expect(infoCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

		var infoResp struct {
			AuthorizationEndpoint string `json:"authorization_endpoint"`
			TokenEndpoint         string `json:"token_endpoint"`
		}

		err := json.Unmarshal(infoCommand.Buffer().Contents(), &infoResp)
		Expect(err).NotTo(HaveOccurred())

		authURL, err = url.Parse(infoResp.AuthorizationEndpoint)
		Expect(err).NotTo(HaveOccurred())

		tokenURL, err = url.Parse(infoResp.TokenEndpoint)
		Expect(err).NotTo(HaveOccurred())
	})

	Describe("login server", func() {
		It("should not allow access to the create account page", func() {
			createAccountURL := authURL
			createAccountURL.Path = "/create_account"

			resp, err := httpClient.Get(createAccountURL.String())
			Expect(err).NotTo(HaveOccurred())

			defer resp.Body.Close()
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "wrong status code, body:\n\n %s", body)
		})

		It("should not allow access to the forgot password page", func() {
			resetPasswordURL := authURL
			resetPasswordURL.Path = "/forgot_password"

			params.Set("username", email)

			resp, err := httpClient.Get(resetPasswordURL.String())
			Expect(err).NotTo(HaveOccurred())

			defer resp.Body.Close()
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "wrong status code, body:\n\n %s", body)
		})
	})

	Describe("auth server", func() {
		It("should not allow access to the create account page", func() {
			createAccountURL := tokenURL
			createAccountURL.Path = "/create_account"

			resp, err := httpClient.Get(createAccountURL.String())
			Expect(err).NotTo(HaveOccurred())

			defer resp.Body.Close()
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(http.StatusNotFound), "wrong status code, body:\n\n %s", body)
		})
	})
})
