package main_test

import (
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	cloudfrontfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	awscloudfront "github.com/aws/aws-sdk-go/service/cloudfront"
)

var _ = Describe("Cloudfront Distribution Instances Gauge", func() {
	var (
		cloudfrontSvc *cloudfront.CloudFrontService
		cloudfrontAPI *cloudfrontfakes.FakeCloudFrontAPI
		logger        lager.Logger

		cloudfrontDistributionSummary []*awscloudfront.DistributionSummary
		listDistributionsStub         = func(
			input *awscloudfront.ListDistributionsInput,
		) (*awscloudfront.ListDistributionsOutput, error) {
			list := awscloudfront.DistributionList{
				Quantity: aws.Int64(int64(len(cloudfrontDistributionSummary))),
				Items:    cloudfrontDistributionSummary,
			}
			resp := awscloudfront.ListDistributionsOutput{
				DistributionList: &list,
			}
			return &resp, nil
		}
	)

	BeforeEach(func() {
		cloudfrontAPI = &cloudfrontfakes.FakeCloudFrontAPI{}
		cloudfrontSvc = &cloudfront.CloudFrontService{Client: cloudfrontAPI}

		cloudfrontAPI.ListDistributionsStub = listDistributionsStub

		logger = lager.NewLogger("cloudfront-distributions-gauge-test")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.DEBUG))
	})

	It("exposes a metric which counts the number of AWS Cloudfront Distributions", func() {
		cloudfrontDistributionSummary = []*awscloudfront.DistributionSummary{
			{Id: aws.String("cfd1")},
			{Id: aws.String("cfd2")},
			{Id: aws.String("cfd3")},
		}

		gauge := CloudfrontDistributionInstancesGauge(logger, cloudfrontSvc, 1*time.Second)

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.cloudfront.distributions.count"))

		Expect(metric.Value).To(Equal(float64(3)))

	})

	It("returns an error if describing AWS Cloudfront Distributions fails", func() {
		cloudfrontAPI.ListDistributionsStub = func(
			_ *awscloudfront.ListDistributionsInput,
		) (*awscloudfront.ListDistributionsOutput, error) {
			return nil, fmt.Errorf("error on purpose")
		}

		gauge := CloudfrontDistributionInstancesGauge(logger, cloudfrontSvc, 1*time.Second)
		Eventually(func() error {
			_, err := gauge.ReadMetric()
			return err
		}, 3*time.Second).ShouldNot(BeNil())
	})
})
