package cf

import (
	"io"

	"github.com/cloudfoundry-incubator/cf-test-helpers/commandstarter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/silentcommandstarter"
	"github.com/onsi/ginkgo"
	"github.com/onsi/gomega/gexec"
)

var Cf = func(args ...string) *gexec.Session {
	cmdStarter := commandstarter.NewCommandStarter()
	return internal.Cf(cmdStarter, args...)
}

func CfSilent(args ...string) *gexec.Session {
	cmdStarter := silentcommandstarter.NewCommandStarter()
	return internal.Cf(cmdStarter, args...)
}

var CfRedact = func(stringToRedact string, args ...string) *gexec.Session {
	var (
		redactor          internal.Redactor
		redactingReporter internal.Reporter
	)
	cmdStarter := silentcommandstarter.NewCommandStarter()
	redactor = internal.NewRedactor(stringToRedact)
	redactingReporter = internal.NewRedactingReporter(ginkgo.GinkgoWriter, redactor)

	return internal.CfWithCustomReporter(cmdStarter, redactingReporter, args...)
}

// CfWithStdin can be used to prepare arbitrary terminal input from the user in the tests.
// Here is an example of how it can be used:
//
// inputConfirmingPrompt := bytes.NewBufferString("yes\n")
// session := cf.CfWithStdin(inputConfirmingPrompt, "update-service", "my-service", "--upgrade")
// Eventually(session).Should(Exit(0))
var CfWithStdin = func(stdin io.Reader, args ...string) *gexec.Session {
	cmdStarter := commandstarter.NewCommandStarterWithStdin(stdin)
	return internal.Cf(cmdStarter, args...)
}
