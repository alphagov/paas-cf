package acceptance_test

import (
	"io/ioutil"
	"net/http"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("custom error page from gorouter", func() {
	var response *http.Response
	var body []byte

	BeforeEach(func() {
		var err error
		response, err = http.Get("https://404-route-that-should-not-exist." + testConfig.GetAppsDomain())
		Expect(err).NotTo(HaveOccurred())

		defer response.Body.Close()
		body, err = ioutil.ReadAll(response.Body)
	})

	Describe("/ endpoint", func() {
		It("should have a status of 404", func() {
			Expect(response.StatusCode).To(Equal(404))
		})

		It("should be of text/html content-type", func() {
			Expect(response.Header.Get("Content-Type")).To(ContainSubstring("text/html"))
		})

		It("should contain govuk-frontend html syntax", func() {
			Expect(body).To(ContainSubstring("class=\"govuk-template\""))
		})

		It("should have a Not Found title", func() {
			Expect(body).To(ContainSubstring("Not Found"))
		})
	})
})
