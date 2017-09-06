package internal_test

import (
	"time"

	"os/exec"

	"bytes"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("RedactingReporter", func() {
	Describe("Report", func() {
		var (
			startTime    time.Time
			cmd          *exec.Cmd
			buffer       *bytes.Buffer
			fakeRedactor *fakes.FakeRedactor

			reporter internal.Reporter
		)

		BeforeEach(func() {
			buffer = &bytes.Buffer{}
			fakeRedactor = &fakes.FakeRedactor{}
		})

		It("prints the time", func() {
			cmd = exec.Command("some-command", "with", "args")
			reporter = internal.NewRedactingReporter(buffer, fakeRedactor)

			reporter.Report(startTime, cmd)

			Expect(buffer.String()).To(ContainSubstring("[0001-01-01 00:00:00.00 (UTC)]>"))
		})

		It("calls the redactor", func() {
			cmd = exec.Command("some-command", "with", "args")
			reporter = internal.NewRedactingReporter(buffer, fakeRedactor)

			reporter.Report(startTime, cmd)

			Expect(fakeRedactor.RedactCallCount()).To(Equal(1))
		})
	})
})
