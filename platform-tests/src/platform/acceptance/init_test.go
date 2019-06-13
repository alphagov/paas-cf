package acceptance_test

import (
	"crypto/tls"
	"net/http"
	"os"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
	"github.com/cloudfoundry/cf-acceptance-tests/helpers/config"
)

const (
	BYTE     = int64(1)
	KILOBYTE = 1024 * BYTE
	MEGABYTE = 1024 * KILOBYTE
	GIGABYTE = 1024 * MEGABYTE
	TERABYTE = 1024 * GIGABYTE

	DEFAULT_MEMORY_LIMIT = "256M"
)

var (
	testConfig  config.CatsConfig
	httpClient  *http.Client
	testContext *workflowhelpers.ReproducibleTestSuiteSetup
)

func TestSuite(t *testing.T) {
	var err error
	RegisterFailHandler(Fail)

	testConfig, err = config.NewCatsConfig(os.Getenv("CONFIG"))
	if err != nil {
		t.Fatal(err)
	}

	httpClient = &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: testConfig.GetSkipSSLValidation()},
		},
	}

	testContext = workflowhelpers.NewTestSuiteSetup(testConfig)

	BeforeSuite(func() {
		testContext.Setup()

		// FIXME this should be removed once these services are generally available.
		org := testContext.GetOrganizationName()
		workflowhelpers.AsUser(testContext.AdminUserContext(), testContext.ShortTimeout(), func() {
			enableServiceAccess := cf.Cf("enable-service-access", "aws-s3-bucket", "-o", org).Wait(testConfig.DefaultTimeoutDuration())
			Expect(enableServiceAccess).To(Exit(0))
			Expect(enableServiceAccess).To(Say("OK"))
		})
	})

	AfterSuite(func() {
		testContext.Teardown()
	})

	componentName := "Custom-Acceptance-Tests"
	if testConfig.GetArtifactsDirectory() != "" {
		helpers.EnableCFTrace(testConfig, componentName)
	}

	RunSpecs(t, componentName)
}
