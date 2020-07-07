package helpers

import (
	"github.com/cloudfoundry-incubator/cf-test-helpers/commandstarter"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers/internal"
	"github.com/cloudfoundry-incubator/cf-test-helpers/internal"
	"github.com/onsi/ginkgo"
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
