package helpers

import (
	"github.com/cloudfoundry/cf-test-helpers/commandstarter"
	"github.com/cloudfoundry/cf-test-helpers/helpers/internal"
	"github.com/cloudfoundry/cf-test-helpers/internal"
	"github.com/onsi/ginkgo/v2"
	"github.com/onsi/gomega/gexec"
)

func Curl(cfg helpersinternal.CurlConfig, args ...string) *gexec.Session {
	cmdStarter := commandstarter.NewCommandStarter()
	return helpersinternal.Curl(cmdStarter, cfg.GetSkipSSLValidation(), args...)
}

func CurlRedact(stringToRedact string, cfg helpersinternal.CurlConfig, args ...string) *gexec.Session {
	cmdStarter := commandstarter.NewCommandStarter()
	redactor := internal.NewRedactor(stringToRedact)
	redactingReporter := internal.NewRedactingReporter(ginkgo.GinkgoWriter, redactor)

	return helpersinternal.CurlWithCustomReporter(cmdStarter, redactingReporter, cfg.GetSkipSSLValidation(), args...)
}

func CurlSkipSSL(skip bool, args ...string) *gexec.Session {
	cmdStarter := commandstarter.NewCommandStarter()
	return helpersinternal.Curl(cmdStarter, skip, args...)
}
