package helpersinternal_test

import (
	"fmt"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/helpers/internal"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("AppUriCreator", func() {
	var cfg config.Config
	var uriCreator *AppUriCreator
	var appsDomain string
	var useHttp bool

	JustBeforeEach(func() {
		cfg = config.Config{
			AppsDomain: appsDomain,
			UseHttp:    useHttp,
		}
		uriCreator = &AppUriCreator{CurlConfig: &cfg}
	})

	Describe("AppUri", func() {
		var path string
		var appName string

		BeforeEach(func() {
			path = "/v2/endpoint"
			useHttp = true
			appName = "my-app"
			appsDomain = "my-domain.org"
		})

		It("computes the url for the given app", func() {
			Expect(uriCreator.AppUri(appName, path)).To(Equal(fmt.Sprintf("http://%s.%s%s", appName, appsDomain, path)))
		})

		Context("when UseHttp is false", func() {
			BeforeEach(func() {
				useHttp = false
			})

			It("computes an https url", func() {
				Expect(uriCreator.AppUri(appName, path)).To(Equal(fmt.Sprintf("https://%s.%s%s", appName, appsDomain, path)))
			})
		})

		Context("when the path is empty", func() {
			BeforeEach(func() {
				path = ""
			})

			It("uses the app root", func() {
				Expect(uriCreator.AppUri(appName, path)).To(Equal(fmt.Sprintf("http://%s.%s", appName, appsDomain)))
			})
		})

		Context("when the path does not start with a '/'", func() {
			BeforeEach(func() {
				path = "v2/endpoint"
			})

			It("prepends the '/'", func() {
				Expect(uriCreator.AppUri(appName, path)).To(Equal(fmt.Sprintf("http://%s.%s/%s", appName, appsDomain, path)))
			})
		})

		Context("when the app name is empty", func() {
			BeforeEach(func() {
				appName = ""
			})

			It("curls the domain", func() {
				Expect(uriCreator.AppUri(appName, path)).To(Equal(fmt.Sprintf("http://%s%s", appsDomain, path)))
			})
		})
	})
})
