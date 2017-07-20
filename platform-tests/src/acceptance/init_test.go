package acceptance_test

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"testing"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

const (
	BYTE     = int64(1)
	KILOBYTE = 1024 * BYTE
	MEGABYTE = 1024 * KILOBYTE
	GIGABYTE = 1024 * MEGABYTE
	TERABYTE = 1024 * GIGABYTE
)

var (
	DEFAULT_TIMEOUT      = 30 * time.Second
	CF_PUSH_TIMEOUT      = 2 * time.Minute
	LONG_CURL_TIMEOUT    = 2 * time.Minute
	CF_JAVA_TIMEOUT      = 10 * time.Minute
	DEFAULT_MEMORY_LIMIT = "256M"

	context    helpers.SuiteContext
	config     helpers.Config
	httpClient *http.Client
)

func TestSuite(t *testing.T) {
	RegisterFailHandler(Fail)

	config = helpers.LoadConfig()

	if config.DefaultTimeout > 0 {
		DEFAULT_TIMEOUT = config.DefaultTimeout * time.Second
	}
	if config.CfPushTimeout > 0 {
		CF_PUSH_TIMEOUT = config.CfPushTimeout * time.Second
	}
	if config.LongCurlTimeout > 0 {
		LONG_CURL_TIMEOUT = config.LongCurlTimeout * time.Second
	}

	httpClient = &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: config.SkipSSLValidation},
		},
	}

	context = helpers.NewContext(config)
	environment := helpers.NewEnvironment(context)

	BeforeSuite(func() {
		environment.Setup()
		// FIXME this should be removed once the broker is generally available.
		org := context.RegularUserContext().Org
		cf.AsUser(context.AdminUserContext(), context.ShortTimeout(), func() {
			enableServiceAccess := cf.Cf("enable-service-access", "mongodb", "-o", org).Wait(DEFAULT_TIMEOUT)
			Expect(enableServiceAccess).To(Exit(0))
			Expect(enableServiceAccess).To(Say("OK"))
		})
	})

	AfterSuite(func() {
		environment.Teardown()
	})

	componentName := "Custom-Acceptance-Tests"
	if config.ArtifactsDirectory != "" {
		helpers.EnableCFTrace(config, componentName)
	}

	RunSpecs(t, componentName)
}

func pollForServiceCreationCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for service creation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("create succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForServiceDeletionCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for service destruction to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "services").Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).ShouldNot(Say(dbInstanceName))
	fmt.Fprint(GinkgoWriter, "done\n")
}
