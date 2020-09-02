package commandstarter

import (
	"io"
	"os/exec"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/onsi/ginkgo"
	"github.com/onsi/gomega/gexec"
)

type CommandStarter struct {
	stdin io.Reader
}

func NewCommandStarter() *CommandStarter {
	return &CommandStarter{}
}

func NewCommandStarterWithStdin(stdin io.Reader) *CommandStarter {
	return &CommandStarter{
		stdin: stdin,
	}
}

func (r *CommandStarter) Start(reporter internal.Reporter, executable string, args ...string) (*gexec.Session, error) {
	cmd := exec.Command(executable, args...)
	cmd.Stdin = r.stdin
	reporter.Report(time.Now(), cmd)

	return gexec.Start(cmd, ginkgo.GinkgoWriter, ginkgo.GinkgoWriter)
}
