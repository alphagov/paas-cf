package helpersinternal_test

import (
	"fmt"
	"os/exec"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/helpers/internal"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gexec"
)

type fakeUriCreator struct {
	toReturn string
}

func (fake *fakeUriCreator) AppUri(appName, path string) string {
	return fake.toReturn
}

var _ = Describe("AppCurler", func() {
	var appCurler *AppCurler
	var curlStub func(CurlConfig, ...string) *gexec.Session
	var uriCreator *fakeUriCreator

	JustBeforeEach(func() {
		appCurler = &AppCurler{
			CurlFunc:   curlStub,
			UriCreator: uriCreator,
		}
	})

	Describe("CurlAndWait", func() {
		var appName, path string
		var timeout time.Duration
		var cfg config.Config
		var args []string
		var curlOutput string

		var curledUri string
		var receivedArgs []string

		BeforeEach(func() {
			appName = "my-app"
			path = "/v2/endpoint"
			timeout = 100 * time.Millisecond
			args = []string{"arg1", "arg2"}
			curlOutput = "curl app"

			curledUri = ""
			receivedArgs = []string{}

			cfg = config.Config{}

			curlStub = func(cfg CurlConfig, args ...string) *gexec.Session {
				Expect(len(args)).To(BeNumerically(">", 0))
				curledUri = args[0]
				receivedArgs = args[1:]

				cmd := exec.Command("bash", "-c", fmt.Sprintf("echo \"%s\"", curlOutput))
				session, _ := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
				return session
			}

			uriCreator = &fakeUriCreator{
				toReturn: appName + ".my-domain.org" + path,
			}
		})

		It("returns the curl output", func() {
			Expect(appCurler.CurlAndWait(&cfg, appName, path, timeout, args...)).To(ContainSubstring(curlOutput))
		})

		It("curls the app uri, as computed by the uriCreator", func() {
			appCurler.CurlAndWait(&cfg, appName, path, timeout, args...)
			Expect(curledUri).To(Equal(uriCreator.toReturn))
		})

		It("passes any args on to the curl function", func() {
			appCurler.CurlAndWait(&cfg, appName, path, timeout, args...)
			Expect(receivedArgs).To(ConsistOf(args))
		})

		Context("when stderr has contents", func() {
			BeforeEach(func() {
				curlStub = func(CurlConfig, ...string) *gexec.Session {
					cmd := exec.Command("bash", "-c", "echo \"curl app\" >&2")
					session, _ := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
					return session
				}
			})

			It("raises a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					appCurler.CurlAndWait(&cfg, appName, path, timeout, args...)
				})

				Expect(failures).To(ContainElement(MatchRegexp("to have length 0")))
			})
		})

		Context("when curl exits with non-zero", func() {
			BeforeEach(func() {
				curlStub = func(CurlConfig, ...string) *gexec.Session {
					cmd := exec.Command("bash", "-c", "exit 1")
					session, _ := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
					return session
				}
			})

			It("raises a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					appCurler.CurlAndWait(&cfg, appName, path, timeout, args...)
				})

				Expect(failures).To(ContainElement(MatchRegexp("to match exit code")))
			})
		})

		Context("when the timeout expires", func() {
			BeforeEach(func() {
				curlStub = func(CurlConfig, ...string) *gexec.Session {
					cmd := exec.Command("bash", "-c", "sleep 1")
					session, _ := gexec.Start(cmd, GinkgoWriter, GinkgoWriter)
					return session
				}
			})

			It("raises a ginkgo error", func() {
				failures := InterceptGomegaFailures(func() {
					appCurler.CurlAndWait(&cfg, appName, path, timeout, args...)
				})

				Expect(failures).To(ContainElement(MatchRegexp("Expected process to exit.")))
			})
		})
	})
})
