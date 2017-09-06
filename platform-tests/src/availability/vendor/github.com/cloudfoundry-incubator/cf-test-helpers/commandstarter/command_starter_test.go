package commandstarter_test

import (
	"os/exec"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/commandstarter"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type fakeReporter struct {
	calledWith struct {
		time time.Time
		cmd  *exec.Cmd
	}
}

func (f *fakeReporter) Report(t time.Time, cmd *exec.Cmd) {
	f.calledWith.time = t
	f.calledWith.cmd = cmd
}

var _ = Describe("CommandStarter", func() {
	var cmdStarter *commandstarter.CommandStarter
	var reporter *fakeReporter

	BeforeEach(func() {
		cmdStarter = commandstarter.NewCommandStarter()
		reporter = &fakeReporter{}
	})

	It("reports the command that it's running", func() {
		cmdStarter.Start(reporter, "bash", "-c", "echo \"hello world\"")
		Expect(reporter.calledWith.cmd.Args).To(Equal([]string{"bash", "-c", "echo \"hello world\""}))
	})
})
