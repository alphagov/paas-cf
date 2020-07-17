package api_availability

import (
	"testing"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var (
	appName        string
	pushTimeout    = 2 * time.Minute
	defaultTimeout = 30 * time.Second
)

var _ = BeforeSuite(func() {
	appName = "api-availability-test-app"

	Expect(cf.Cf(
		"push", appName,
		"-p", "../../example-apps/static-app",
		"-b", "staticfile_buildpack",
		"-m", "64M",
	).Wait(pushTimeout)).To(Exit(0))
})

var _ = AfterSuite(func() {
	cf.Cf("delete", appName, "-f", "-r").Wait(defaultTimeout)
})

func TestSuite(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "API Availability test")
}
