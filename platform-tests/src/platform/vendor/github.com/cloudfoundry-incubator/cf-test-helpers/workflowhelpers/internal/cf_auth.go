package internal

import (
	"fmt"
	"os/exec"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/onsi/ginkgo"
	"github.com/onsi/ginkgo/config"
	"github.com/onsi/gomega/gexec"
)

func CfAuth(cmdStarter internal.Starter, user string, password string) *gexec.Session {
	reporter := &sanitizedReporter{}
	auth, err := cmdStarter.Start(reporter, "cf", "auth", user, password)
	if err != nil {
		panic(err)
	}
	return auth
}

const timeFormat = "2006-01-02 15:04:05.00 (MST)"

type sanitizedReporter struct{}

func (r *sanitizedReporter) Report(startTime time.Time, cmd *exec.Cmd) {
	cfCmd := cmd.Args[0]
	authCmd := cmd.Args[1]
	user := cmd.Args[2]

	startColor := ""
	endColor := ""
	if !config.DefaultReporterConfig.NoColor {
		startColor = "\x1b[32m"
		endColor = "\x1b[0m"
	}
	fmt.Fprintf(
		ginkgo.GinkgoWriter,
		"\n%s[%s]> %s %s %s %s %s\n",
		startColor,
		startTime.UTC().Format(timeFormat),
		cfCmd,
		authCmd,
		user,
		"[REDACTED]",
		endColor)
}
