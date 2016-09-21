package acceptance_test

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"regexp"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

const (
	DB_CREATE_TIMEOUT = 30 * time.Minute
)

var _ = Describe("RDS broker", func() {
	const (
		serviceName  = "postgres"
		testPlanName = "M-dedicated-9.5"
		region       = "eu-west-1"
	)

	It("should have registered the postgres service", func() {
		plans := cf.Cf("marketplace").Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(DEFAULT_TIMEOUT)
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say("M-dedicated-9.5"))
		Expect(plans).To(Say("M-HA-dedicated-9.5"))
	})

	Context("creating a database instance with default settings", func() {
		// Avoid creating additional tests in this block because this setup and teardown is
		// slow (several minutes).

		var (
			appName         string
			dbInstanceName  string
			rdsInstanceName string
		)
		BeforeEach(func() {
			appName = generator.PrefixedRandomName("CATS-APP-")
			dbInstanceName = generator.PrefixedRandomName("test-db-")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			pollForRDSCreationCompletion(dbInstanceName)

			rdsInstanceName = getRDSInstanceName(dbInstanceName)
			fmt.Fprintf(GinkgoWriter, "Created RDS instance: %s\n", rdsInstanceName)

			Expect(cf.Cf(
				"push", appName,
				"--no-start",
				"-b", config.GoBuildpackName,
				"-p", "../../example-apps/healthcheck",
				"-f", "../../example-apps/healthcheck/manifest.yml",
				"-d", config.AppsDomain,
			).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

			Expect(cf.Cf("bind-service", appName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
		})

		AfterEach(func() {
			cf.Cf("delete", appName, "-f").Wait(DEFAULT_TIMEOUT)

			Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			// Poll until destruction is complete, otherwise the org cleanup fails.
			pollForRDSDeletionCompletion(dbInstanceName)

			rdsClient, err := NewRDSClient(region)
			Expect(err).NotTo(HaveOccurred())
			snapshots, err := rdsClient.GetDBFinalSnapshots(rdsInstanceName)
			fmt.Fprintf(GinkgoWriter, "Final snapshots for %s:\n", rdsInstanceName)
			fmt.Fprint(GinkgoWriter, snapshots)
			Expect(err).NotTo(HaveOccurred())
			Expect(snapshots).Should(ContainSubstring(rdsInstanceName))

			snapshotDeletionOutput, err := rdsClient.deleteDBFinalSnapshot(rdsInstanceName)
			fmt.Fprintf(GinkgoWriter, "Snapshot deletion output for %s:\n", rdsInstanceName)
			fmt.Fprint(GinkgoWriter, snapshotDeletionOutput)
			Expect(err).NotTo(HaveOccurred())
		})

		It("can connect to the DB instance from the app", func() {
			By("Sending request to DB Healthcheck app")
			resp, err := httpClient.Get(helpers.AppUri(appName, "/db"))
			Expect(err).NotTo(HaveOccurred())
			body, err := ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))

			By("Sending request to DB Healthcheck app without TLS")
			resp, err = httpClient.Get(helpers.AppUri(appName, "/db?ssl=false"))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).NotTo(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			Expect(body).To(MatchRegexp("no pg_hba.conf entry for .* SSL off"), "Connection without TLS did not report a TLS error")

			By("Testing permissions after unbind and rebind")
			resp, err = httpClient.Get(helpers.AppUri(appName, "/db/permissions-check?phase=setup"))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response setting up multi-user test table. Response body:\n%s\n", resp.StatusCode, string(body))

			Expect(cf.Cf("stop", appName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))
			Expect(cf.Cf("unbind-service", appName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))
			Expect(cf.Cf("bind-service", appName, dbInstanceName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))
			Expect(cf.Cf("start", appName).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			resp, err = httpClient.Get(helpers.AppUri(appName, "/db/permissions-check?phase=test"))
			Expect(err).NotTo(HaveOccurred())
			body, err = ioutil.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.StatusCode).To(Equal(200), "Got %d response testing multi-user permissions. Response body:\n%s\n", resp.StatusCode, string(body))
		})
	})

	Context("creating a database instance with custom parameters", func() {

		var (
			dbInstanceName  string
			rdsInstanceName string
		)

		BeforeEach(func() {
			dbInstanceName = generator.PrefixedRandomName("test-db-")
			Expect(cf.Cf("create-service", serviceName, testPlanName, dbInstanceName, "-c", `{"skip_final_snapshot": "true"}`).Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			pollForRDSCreationCompletion(dbInstanceName)

			rdsInstanceName = getRDSInstanceName(dbInstanceName)
			fmt.Fprintf(GinkgoWriter, "Created RDS instance: %s\n", rdsInstanceName)
		})

		It("should not create a final snapshot when `skip_final_snapshot` is set to true", func() {
			Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			// Poll until destruction is complete, otherwise the org cleanup fails.
			pollForRDSDeletionCompletion(dbInstanceName)

			rdsClient, err := NewRDSClient(region)
			Expect(err).NotTo(HaveOccurred())
			snapshots, err := rdsClient.GetDBFinalSnapshots(rdsInstanceName)
			fmt.Fprintf(GinkgoWriter, "Final snapshots for %s:\n", rdsInstanceName)
			fmt.Fprint(GinkgoWriter, snapshots)
			Expect(err).To(HaveOccurred())
			Expect(err.Error()).Should(ContainSubstring("DBSnapshotNotFound"))

			snapshotDeletionOutput, err := rdsClient.deleteDBFinalSnapshot(rdsInstanceName)
			fmt.Fprintf(GinkgoWriter, "Snapshot deletion output for %s:\n", rdsInstanceName)
			fmt.Fprint(GinkgoWriter, snapshotDeletionOutput)
			Expect(err).To(HaveOccurred())
		})

		It("should create a final snapshot if we set `skip_final_snapshot` back to false", func() {
			Expect(cf.Cf("update-service", dbInstanceName, "-c", `{"skip_final_snapshot": "false"}`).Wait(DEFAULT_TIMEOUT)).To(Exit(0))
			pollForRDSUpdateCompletion(dbInstanceName)
			Expect(cf.Cf("delete-service", dbInstanceName, "-f").Wait(DEFAULT_TIMEOUT)).To(Exit(0))

			// Poll until destruction is complete, otherwise the org cleanup fails.
			pollForRDSDeletionCompletion(dbInstanceName)

			rdsClient, err := NewRDSClient(region)
			Expect(err).NotTo(HaveOccurred())
			snapshots, err := rdsClient.GetDBFinalSnapshots(rdsInstanceName)
			fmt.Fprintf(GinkgoWriter, "Final snapshots for %s:\n", rdsInstanceName)
			fmt.Fprint(GinkgoWriter, snapshots)
			Expect(err).NotTo(HaveOccurred())
			Expect(snapshots).Should(ContainSubstring(rdsInstanceName))

			snapshotDeletionOutput, err := rdsClient.deleteDBFinalSnapshot(rdsInstanceName)
			fmt.Fprintf(GinkgoWriter, "Snapshot deletion output for %s:\n", rdsInstanceName)
			fmt.Fprint(GinkgoWriter, snapshotDeletionOutput)
			Expect(err).NotTo(HaveOccurred())
		})
	})
})

func pollForRDSCreationCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for RDS creation to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("create succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForRDSDeletionCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for RDS destruction to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "services").Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).ShouldNot(Say(dbInstanceName))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func pollForRDSUpdateCompletion(dbInstanceName string) {
	fmt.Fprint(GinkgoWriter, "Polling for RDS update to complete")
	Eventually(func() *Buffer {
		fmt.Fprint(GinkgoWriter, ".")
		command := quietCf("cf", "service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
		Expect(command).To(Exit(0))
		return command.Out
	}, DB_CREATE_TIMEOUT, 15*time.Second).Should(Say("update succeeded"))
	fmt.Fprint(GinkgoWriter, "done\n")
}

func getRDSInstanceName(dbInstanceName string) string {
	serviceOutput := cf.Cf("service", dbInstanceName).Wait(DEFAULT_TIMEOUT)
	Expect(serviceOutput).To(Exit(0))
	rxp, _ := regexp.Compile("rdsbroker-([a-z0-9-]+)")
	return string(rxp.Find(serviceOutput.Out.Contents()))
}

// quietCf is an equivelent of cf.Cf that doesn't send the output to
// GinkgoWriter. Used when you don't want the output, even in verbose mode (eg
// when polling the API)
func quietCf(program string, args ...string) *Session {
	command, err := Start(exec.Command(program, args...), nil, nil)
	Expect(err).NotTo(HaveOccurred())
	return command
}

type RDSClient struct {
	region string
	rdssvc *rds.RDS
}

func NewRDSClient(region string) (*RDSClient, error) {
	sess, err := session.NewSession(&aws.Config{Region: aws.String(region)})
	if err != nil {
		fmt.Println("Failed to create AWS session,", err)
		return nil, err
	}

	rdssvc := rds.New(sess)
	return &RDSClient{
		region: region,
		rdssvc: rdssvc,
	}, nil
}

func (r *RDSClient) GetDBFinalSnapshots(ID string) (*rds.DescribeDBSnapshotsOutput, error) {
	params := &rds.DescribeDBSnapshotsInput{
		DBSnapshotIdentifier: aws.String(ID + "-final-snapshot"),
	}

	resp, err := r.rdssvc.DescribeDBSnapshots(params)

	if err != nil {
		return nil, err
	}
	return resp, nil
}

func (r *RDSClient) deleteDBFinalSnapshot(ID string) (*rds.DeleteDBSnapshotOutput, error) {
	params := &rds.DeleteDBSnapshotInput{
		DBSnapshotIdentifier: aws.String(ID + "-final-snapshot"),
	}

	resp, err := r.rdssvc.DeleteDBSnapshot(params)

	if err != nil {
		return nil, err
	}
	return resp, nil
}
