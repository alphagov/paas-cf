package broker_acceptance_test

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"testing"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-community/go-cfclient"
	"github.com/cloudfoundry/cf-acceptance-tests/helpers/config"
	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/helpers"
	"github.com/cloudfoundry/cf-test-helpers/workflowhelpers"
)

const (
	DB_CREATE_TIMEOUT = 30 * time.Minute
)

var (
	testConfig  config.CatsConfig
	httpClient  *http.Client
	testContext *workflowhelpers.ReproducibleTestSuiteSetup
	altOrgName  string

	systemDomain = os.Getenv("SYSTEM_DNS_ZONE_NAME")

	cfClient *cfclient.Client
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
	altOrgName = testContext.TestSpace.OrganizationName() + "-alt"

	BeforeSuite(func() {
		testContext.Setup()

		Expect(systemDomain).NotTo(Equal(""))

		username := testContext.RegularUserContext().Username

		var err error
		cfClient, err = cfclient.NewClient(&cfclient.Config{
			ApiAddress: "https://" + testContext.RegularUserContext().ApiUrl,
			Username:   username,
			Password:   testContext.RegularUserContext().Password,
		})
		Expect(err).NotTo(HaveOccurred())

		workflowhelpers.AsUser(testContext.AdminUserContext(), testContext.ShortTimeout(), func() {
			orgManager := cf.Cf("set-org-role", username, testContext.TestSpace.OrganizationName(), "OrgManager").Wait(testConfig.DefaultTimeoutDuration())
			Expect(orgManager).To(Exit(0))

			altOrg := cf.Cf("create-org", altOrgName).Wait(testConfig.DefaultTimeoutDuration())
			Expect(altOrg).To(Exit(0))
			altOrgManager := cf.Cf("set-org-role", username, altOrgName, "OrgManager").Wait(testConfig.DefaultTimeoutDuration())
			Expect(altOrgManager).To(Exit(0))
		})
	})

	AfterSuite(func() {
		workflowhelpers.AsUser(testContext.AdminUserContext(), testContext.ShortTimeout(), func() {
			deleteAltOrg := cf.Cf("delete-org", altOrgName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			Expect(deleteAltOrg).To(Exit(0))
		})
		testContext.Teardown()
	})

	componentName := "Custom-Acceptance-Tests"
	if testConfig.GetArtifactsDirectory() != "" {
		helpers.EnableCFTrace(testConfig, componentName)
	}

	RunSpecs(t, componentName)
}

// quietCf is an equivelent of cf.Cf that doesn't send the output to
// GinkgoWriter. Used when you don't want the output, even in verbose mode (eg
// when polling the API)
func quietCf(program string, args ...string) *Session {
	command, err := Start(exec.Command(program, args...), nil, nil)
	Expect(err).NotTo(HaveOccurred())
	return command
}

func pollForServiceCreationCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for service creation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf service creation phase: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("create succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForCdnServiceCreationCompletion(cdnInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for CDN service creation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", cdnInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf service creation phase: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("PENDING_VALIDATION"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForServiceUpdateCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for service update to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf service update phase: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("update succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForServiceDeletionCompletion(dbInstanceName string) {
	pollForServiceDeletionCompletionTimeout(dbInstanceName, testConfig.DefaultTimeoutDuration())
}

func pollForServiceDeletionCompletionTimeout(dbInstanceName string, timeout time.Duration) {
	fmt.Fprint(GinkgoWriter, "Polling for service destruction to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "services").Wait(timeout)
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf services: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).ShouldNot(Say(dbInstanceName))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForServiceBound(dbInstanceName, boundAppName string) {
	fmt.Fprint(GinkgoWriter, "Polling for async bind operation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf service: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 5*time.Second).Should(Say(boundAppName))
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf service: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 5*time.Second).ShouldNot(Say("in progress"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForServiceUnbound(dbInstanceName, boundAppName string) {
	fmt.Fprint(GinkgoWriter, "Polling for async unbind operation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0), fmt.Sprint("Error calling cf service: ", string(command.Out.Contents())))
		return command.Out
	}, DB_CREATE_TIMEOUT, 5*time.Second).ShouldNot(Say(boundAppName))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func serviceInstancePurge(serviceInstanceName string, orgName string) {
	workflowhelpers.AsUser(testContext.AdminUserContext(), testContext.ShortTimeout(), func() {
		command := cf.Cf("target", "-o", orgName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0))
		command = cf.Cf("purge-service-instance", serviceInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())
		Expect(command).To(Exit(0))
	})
}

type basicAuthRoundTripper struct {
	username string
	password string
}

func (r basicAuthRoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	req.SetBasicAuth(r.username, r.password)
	return http.DefaultTransport.RoundTrip(req)
}
