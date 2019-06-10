package helpersinternal_test

import (
	"bytes"
	"fmt"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/commandreporter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Curl", func() {
	var cmdTimeout time.Duration
	var starter *fakes.FakeCmdStarter

	BeforeEach(func() {
		cmdTimeout = 30 * time.Second
		starter = fakes.NewFakeCmdStarter()

		starter.ToReturn[0].Output = "HTTP/1.1 200 OK"
	})

	Context("when using Curl", func() {
		It("uses a default reporter", func() {
			Eventually(helpersinternal.Curl(starter, false, "-I", "http://example.com"), 1*time.Second).Should(Exit(0))
			Expect(starter.CalledWith[0].Reporter).To(BeAssignableToTypeOf(commandreporter.NewCommandReporter()))
		})
	})

	Context("when using CurlWithCustomReporter", func() {
		var (
			buffer            *bytes.Buffer
			fakeRedactor      *fakes.FakeRedactor
			redactingReporter internal.Reporter
		)

		BeforeEach(func() {
			buffer = new(bytes.Buffer)
			fakeRedactor = new(fakes.FakeRedactor)
			redactingReporter = internal.NewRedactingReporter(buffer, fakeRedactor)
		})

		It("outputs the body of the given URL", func() {
			session := helpersinternal.CurlWithCustomReporter(starter, redactingReporter, false, "-I", "http://example.com")

			session.Wait(cmdTimeout)
			Expect(session).To(Exit(0))
			Expect(session.Out).To(Say("HTTP/1.1 200 OK"))
			Expect(starter.CalledWith[0].Executable).To(Equal("curl"))
			Expect(starter.CalledWith[0].Args).To(ConsistOf("-H", "Expect:", "-I", "-s", "http://example.com"))
		})

		It("uses the specified reporter", func() {
			Eventually(helpersinternal.CurlWithCustomReporter(starter, redactingReporter, false, "-I", "http://example.com"), 1*time.Second).Should(Exit(0))

			Expect(starter.CalledWith[0].Reporter).To(BeAssignableToTypeOf(new(internal.RedactingReporter)))
		})

		Context("when the starter returns an error", func() {
			BeforeEach(func() {
				starter.ToReturn[0].Err = fmt.Errorf("error")
			})

			It("panics when the starter returns an error", func() {
				Expect(func() {
					helpersinternal.CurlWithCustomReporter(starter, redactingReporter, false, "-I", "http://example.com")
				}).To(Panic())
			})
		})
	})
})
