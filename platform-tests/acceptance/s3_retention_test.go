package acceptance_test

import (
	"os"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func GetConfigFromEnvironment(varName string) string {
	configValue := os.Getenv(varName)
	ExpectWithOffset(1, configValue).NotTo(BeEmpty(), "Environment variable $%s is not set", varName)
	return configValue
}

var _ = Describe("S3 logs bucket", func() {
	const (
		expectedRetention = 30
	)

	It("should have retention period set to "+strconv.Itoa(expectedRetention)+" days", func() {
		sess, err := session.NewSession()
		Expect(err).NotTo(HaveOccurred())

		svc := s3.New(sess)
		bucket := "gds-paas-" + GetConfigFromEnvironment("DEPLOY_ENV") + "-elb-access-log"
		getBucketInput := &s3.GetBucketLifecycleConfigurationInput{
			Bucket: aws.String(bucket),
		}

		req, resp := svc.GetBucketLifecycleConfigurationRequest(getBucketInput)

		err = req.Send()
		Expect(err).NotTo(HaveOccurred())

		Expect(*resp.Rules[0].Expiration.Days).To(BeNumerically("==", expectedRetention))
	})
})
