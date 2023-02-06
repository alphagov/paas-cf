package acceptance_test

import (
	"fmt"
	"os"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/generator"
)

func AppCurl(appName string, url string) string {

	cfSSHCommand := cf.Cf("ssh", appName, "-c", fmt.Sprintf("curl -s -o /dev/null -I -w \"%%{http_code}\" %s", url))
	session := cfSSHCommand.Wait(testConfig.DefaultTimeoutDuration())
	Expect(session).To(Exit(0))
	return string(session.Out.Contents())
}

var _ = Describe("AWS Endpoint Check", Ordered, func() {
	Context("when calling aws endpoints", func() {

		var (
			appName string
			region  string
			err     error
		)

		BeforeAll(func() {
			region = os.Getenv("AWS_REGION")
			Expect(region).NotTo(BeEmpty())
			Expect(err).NotTo(HaveOccurred())

			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			Expect(cf.Cf(
				"push", appName,
				"--no-start",
				"-m", DEFAULT_MEMORY_LIMIT,
				"-p", "../example-apps/simple-python-app",
				"-b", "python_buildpack",
				"-c", "python hello.py",
			).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		})

		AfterAll(func() {
			Expect(cf.Cf("delete", appName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
		})

		DescribeTable("should connect to aws endpoints",
			func(endpoint string, expectedResponse string) {
				Expect(AppCurl(appName, fmt.Sprintf("https://%s.%s.amazonaws.com", endpoint, region))).To(Equal(expectedResponse))
			},
			Entry("should connect to secrets manager endpoint", "secretsmanager", "404"),
			Entry("should connect to dynamodb endpoint", "dynamodb", "404"),
			Entry("should connect to kms endpoint", "kms", "404"),
			Entry("should connect to grafana endpoint", "grafana", "403"),
			Entry("should connect to prometheus endpoint", "aps", "403"),
			Entry("should connect to rekognition endpoint", "rekognition", "404"),
			Entry("should connect to s3 endpoint", "s3", "405"),
			Entry("should connect to ses endpoint", "email", "404"),
			Entry("should connect to sms endpoint", "sms", "404"),
			Entry("should connect to cassandra endpoint", "cassandra", "404"),
			Entry("should connect to sqs endpoint", "sqs", "404"),
			Entry("should connect to sns endpoint", "sns", "404"),
		)

		It("should connect to cloudfront endpoint", func() {
			Expect(AppCurl(appName, "https://cloudfront.amazonaws.com")).To(Equal("404"))
		})
	})
})
