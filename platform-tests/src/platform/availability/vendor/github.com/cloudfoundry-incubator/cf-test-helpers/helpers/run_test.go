package helpers_test

import (
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Run", func() {
	var cmdTimeout time.Duration
	BeforeEach(func() {
		cmdTimeout = 30 * time.Second
	})

	It("runs the given command", func() {
		session := helpers.Run("bash", "-c", "echo hi out; echo hi err 1>&2; exit 42")

		session.Wait(cmdTimeout)
		Expect(session).To(Exit(42))
		Expect(session.Out).To(Say("hi out"))
		Expect(session.Err).To(Say("hi err"))
	})

	Context("when the starter returns an error", func() {
		It("panics", func() {
			Expect(func() {
				helpers.Run("fakeExecutable", "arg")
			}).To(Panic())
		})
	})
})
