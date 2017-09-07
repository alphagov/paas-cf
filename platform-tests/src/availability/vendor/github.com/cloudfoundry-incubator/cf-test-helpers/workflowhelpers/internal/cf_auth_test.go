package internal_test

import (
	"bytes"
	"fmt"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal/fakes"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers/internal"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("CfAuth", func() {
	var cmdStarter *fakes.FakeCmdStarter
	var reporterOutput *bytes.Buffer

	BeforeEach(func() {
		cmdStarter = fakes.NewFakeCmdStarter()
		reporterOutput = bytes.NewBuffer([]byte{})
		GinkgoWriter = reporterOutput
	})

	It("runs the cf auth command", func() {
		internal.CfAuth(cmdStarter, "user", "password").Wait()
		Expect(cmdStarter.CalledWith[0].Executable).To(Equal("cf"))
		Expect(cmdStarter.CalledWith[0].Args).To(Equal([]string{"auth", "user", "password"}))
	})

	It("does not reveal the password", func() {
		internal.CfAuth(cmdStarter, "user", "password").Wait()
		Expect(reporterOutput.String()).To(ContainSubstring("REDACTED"))
		Expect(reporterOutput.String()).NotTo(ContainSubstring("password"))
	})

	Context("when the starter returns error", func() {
		BeforeEach(func() {
			cmdStarter.ToReturn[0].Err = fmt.Errorf("something went wrong")
		})

		It("panics", func() {
			Expect(func() {
				internal.CfAuth(cmdStarter, "user", "password").Wait()
			}).To(Panic())
		})
	})
})
