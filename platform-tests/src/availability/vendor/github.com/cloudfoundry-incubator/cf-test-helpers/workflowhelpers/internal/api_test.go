package internal_test

import (
	"fmt"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type genericResource struct {
	Foo string
}

var _ = Describe("ApiRequest", func() {
	var starter *fakes.FakeCmdStarter
	var timeout time.Duration
	BeforeEach(func() {
		starter = fakes.NewFakeCmdStarter()
		starter.ToReturn[0].Output = `\{\"foo\": \"bar\"\}`
		timeout = 1 * time.Second
	})

	It("sends the request to the current CF target", func() {
		var response genericResource
		ApiRequest(starter, "GET", "/v2/info", &response, timeout, "some", "data")
		Expect(starter.CalledWith[0].Executable).To(Equal("cf"))
		Expect(starter.CalledWith[0].Args).To(Equal([]string{"curl", "/v2/info", "-X", "GET", "-d", "somedata"}))

		Expect(response.Foo).To(Equal("bar"))
	})

	Context("when command starter returns a nil response", func() {
		It("does not fail", func() {
			failures := InterceptGomegaFailures(func() {
				ApiRequest(starter, "GET", "/v2/info", nil, timeout)
			})
			Expect(failures).To(BeEmpty())
		})
	})

	Context("when request data is empty", func() {
		It("doesn't include a -d argument", func() {
			ApiRequest(starter, "GET", "/v2/info", nil, timeout)
			Expect(starter.CalledWith[0].Args).NotTo(ContainElement("-d"))
		})
	})

	Context("when there is an error from the starter", func() {
		BeforeEach(func() {
			starter.ToReturn[0].Err = fmt.Errorf("something went wrong")
		})

		It("fails with a ginkgo error", func() {
			failures := InterceptGomegaFailures(func() {
				ApiRequest(starter, "GET", "/v2/info", nil, timeout)
			})
			Expect(failures).To(ContainElement(MatchRegexp("something went wrong\n.*not to have occurred")))
		})
	})

	Context("when the process exits with non-zero code", func() {
		BeforeEach(func() {
			starter.ToReturn[0].ExitCode = 1
		})

		It("fails with a ginkgo error", func() {
			failures := InterceptGomegaFailures(func() {
				ApiRequest(starter, "GET", "/v2/info", nil, timeout)
			})
			Expect(failures).To(ContainElement(MatchRegexp("1\n.*to match exit code:\n.*0")))
		})
	})

	Context("when the process takes too long to exit", func() {
		BeforeEach(func() {
			timeout = 1 * time.Millisecond
		})

		It("fails with a ginkgo error", func() {
			failures := InterceptGomegaFailures(func() {
				ApiRequest(starter, "GET", "/v2/info", nil, timeout)
			})
			Expect(failures).To(ContainElement(MatchRegexp("Timed out after 0.00[1-2]s.\nExpected process to exit.  It did not.")))
		})
	})

	Context("when there is an error unmarshaling the api response", func() {
		BeforeEach(func() {
			starter.ToReturn[0].Output = `{{{`
		})

		It("fails with a ginkgo error", func() {
			failures := InterceptGomegaFailures(func() {
				var response genericResource
				ApiRequest(starter, "GET", "/v2/info", &response, timeout)
			})
			Expect(failures).To(ContainElement(MatchRegexp("json.SyntaxError")))
		})
	})
})
