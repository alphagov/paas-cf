package performance_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/cloudfoundry-incubator/cf-test-helpers/config"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
)

const (
	DEFAULT_MEMORY_LIMIT = "256M"
)

var (
	testConfig *config.Config
)

func TestSuite(t *testing.T) {
	RegisterFailHandler(Fail)

	testConfig = config.LoadConfig()

	testContext := workflowhelpers.NewTestSuiteSetup(testConfig)

	BeforeSuite(func() {
		testContext.Setup()
	})

	AfterSuite(func() {
		testContext.Teardown()
	})

	RunSpecs(t, "Performance tests")
}
