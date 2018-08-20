package internal_test

import (
	"fmt"

	"bytes"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	. "github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("CfAuth", func() {
	var (
		password string

		cmdStarter *fakes.FakeCmdStarter

		redactor          internal.Redactor
		reporterOutput    *bytes.Buffer
		redactingReporter internal.Reporter
	)

	BeforeEach(func() {
		password = "foobar"
		cmdStarter = fakes.NewFakeCmdStarter()
		redactor = internal.NewRedactor(password)
		reporterOutput = bytes.NewBuffer([]byte{})
		redactingReporter = internal.NewRedactingReporter(reporterOutput, redactor)
	})

	It("runs the cf auth command", func() {
		CfAuth(cmdStarter, redactingReporter, "user", password).Wait()
		Expect(cmdStarter.CalledWith[0].Executable).To(Equal("cf"))
		Expect(cmdStarter.CalledWith[0].Args).To(Equal([]string{"auth", "user", "foobar"}))
	})

	It("does not reveal the password", func() {
		CfAuth(cmdStarter, redactingReporter, "user", password).Wait()
		Expect(reporterOutput.String()).To(ContainSubstring("REDACTED"))
		Expect(reporterOutput.String()).NotTo(ContainSubstring("foobar"))
	})

	Context("when the starter returns error", func() {
		BeforeEach(func() {
			cmdStarter.ToReturn[0].Err = fmt.Errorf("something went wrong")
		})

		It("panics", func() {
			Expect(func() {
				CfAuth(cmdStarter, redactingReporter, "user", password).Wait()
			}).To(Panic())
		})
	})
})
