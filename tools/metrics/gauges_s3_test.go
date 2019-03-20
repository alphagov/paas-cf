package main_test

import (
	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/fakes"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	"time"
)

var _ = Describe("S3 Gauges", func() {
	var (
		logger	lager.Logger
		log		*gbytes.Buffer
		s3API	*fakes.FakeS3API
		s3Service *S3Service
	)

	BeforeEach(func(){
		logger = lager.NewLogger("logger")
		log = gbytes.NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(log, lager.INFO))

		s3API = &fakes.FakeS3API{}
		s3Service = &S3Service{Client: s3API}
	})

	It("returns zero if there are no buckets", func() {
		s3API.ListBucketsReturns(&s3.ListBucketsOutput{
			Buckets: []*s3.Bucket{},
		}, nil)

		gauge := S3BucketsGauge(logger, s3Service, 1*time.Second)

		defer gauge.Close()

		var metric Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.s3.buckets.count"))

		Expect(metric.Value).To(Equal(float64(0)))
		Expect(metric.Kind).To(Equal(Gauge))
	})

	It("returns the correct number of buckets when there are buckets", func(){
		s3Buckets := []*s3.Bucket{
			&s3.Bucket{
				Name: aws.String("bucket-1"),
			},
			&s3.Bucket{
				Name: aws.String("bucket-2"),
			},
			&s3.Bucket{
				Name: aws.String("bucket-3"),
			},
		}
		s3API.ListBucketsReturns(&s3.ListBucketsOutput{
			Buckets: s3Buckets,
		}, nil)

		gauge := S3BucketsGauge(logger, s3Service, 1*time.Second)

		defer gauge.Close()

		var metric Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3*time.Second).Should(Equal("aws.s3.buckets.count"))

		Expect(metric.Value).To(Equal(float64(3)))
		Expect(metric.Kind).To(Equal(Gauge))
	})
})
