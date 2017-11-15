package acceptance_test

import (
	"encoding/json"
	"github.com/PuerkitoBio/goquery"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	"io/ioutil"
	"net/url"
)

var _ = Describe("UAA Styling", func() {
	var uaaURL *url.URL
	var uaaLoginURL url.URL
	var uaaStylesheetURL url.URL
	var customStylesheetURL url.URL

	BeforeEach(func() {
		infoCommand := cf.Cf("curl", "/v2/info")
		Expect(infoCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

		var infoResp struct {
			TokenEndpoint string `json:"token_endpoint"`
		}
		err := json.Unmarshal(infoCommand.Buffer().Contents(), &infoResp)
		Expect(err).NotTo(HaveOccurred())

		uaaURL, err = url.Parse(infoResp.TokenEndpoint)
		Expect(err).NotTo(HaveOccurred())

		uaaLoginURL = *uaaURL
		uaaLoginURL.Path = "/login"

		uaaStylesheetURL = *uaaURL
		uaaStylesheetURL.Path = "/resources/oss/stylesheets/application.css"

		customStylesheetURL = url.URL{
			Scheme: "https",
			Host:   "paas-uaa-assets." + testConfig.AppsDomain,
			Path:   "/stylesheets/application.css",
		}
	})

	It("should be using the custom stylesheet", func() {
		response, err := httpClient.Get(uaaLoginURL.String())
		Expect(err).NotTo(HaveOccurred())
		uaaLoginDoc, err := goquery.NewDocumentFromResponse(response)
		Expect(err).NotTo(HaveOccurred())

		stylesheetHrefs := uaaLoginDoc.Find("link[rel=stylesheet]").Map(func(_ int, linkTag *goquery.Selection) string {
			href, _ := linkTag.Attr("href")
			return href
		})
		Expect(stylesheetHrefs).To(HaveLen(2))
		Expect(stylesheetHrefs[0]).To(Equal("/vendor/font-awesome/css/font-awesome.min.css"))
		Expect(stylesheetHrefs[1]).To(Equal(customStylesheetURL.String()))
	})

	It("should have the expected default stylesheet", func() {
		response, err := httpClient.Get(uaaStylesheetURL.String())
		Expect(err).NotTo(HaveOccurred())
		returnedBody, err := ioutil.ReadAll(response.Body)
		Expect(err).NotTo(HaveOccurred())

		expectedBody, err := ioutil.ReadFile("expected_uaa_stylesheet.css")
		Expect(err).NotTo(HaveOccurred())
		Expect(string(returnedBody)).To(Equal(string(expectedBody)))
	})
})
