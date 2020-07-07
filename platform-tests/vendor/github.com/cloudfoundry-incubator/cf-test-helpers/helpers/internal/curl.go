package helpersinternal

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/commandreporter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/onsi/gomega/gexec"
)

func Curl(cmdStarter internal.Starter, skipSsl bool, args ...string) *gexec.Session {
	return CurlWithCustomReporter(cmdStarter, commandreporter.NewCommandReporter(), skipSsl, args...)
}

func CurlWithCustomReporter(cmdStarter internal.Starter, reporter internal.Reporter, skipSsl bool, args ...string) *gexec.Session {
	curlArgs := append([]string{"-s"}, args...)
	curlArgs = append([]string{"-H", "Expect:"}, curlArgs...)
	if skipSsl {
		curlArgs = append([]string{"-k"}, curlArgs...)
	}

	request, err := cmdStarter.Start(reporter, "curl", curlArgs...)

	if err != nil {
		panic(err)
	}

	return request
}
