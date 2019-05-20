package main_test

import (
	"code.cloudfoundry.org/lager"
	"fmt"
	"github.com/alphagov/paas-cf/tools/metrics/fakes"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"time"

	. "github.com/alphagov/paas-cf/tools/metrics"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type CloudFrontServiceStub struct {
	domains []CustomDomain
}

func (cf *CloudFrontServiceStub) CustomDomains() ([]CustomDomain, error) {
	return cf.domains, nil
}

var _ = Describe("GaugesCustomDomainCDNMetrics", func() {

	var logger lager.Logger
	var cloudwatchFake fakes.FakeCloudWatchAPI
	var cloudwatchService CloudWatchService

	BeforeEach(func() {
		logger = lager.NewLogger("gauges_custom_domain_cdn_metrics_test")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.DEBUG))
		cloudwatchFake.GetMetricStatisticsCalls(
			func(input *cloudwatch.GetMetricStatisticsInput) (*cloudwatch.GetMetricStatisticsOutput, error) {
				output := cloudwatch.GetMetricStatisticsOutput{
					Datapoints: nil,
					Label:      nil,
				}

				type metrics struct {
					requests        float64
					bytesdownloaded float64
					bytesuploaded   float64
					totalerrorrate  float64
					fourxxerrorrate float64
					fivexxerrorrate float64
				}

				cases := map[string]metrics{
					"dist-1": {
						requests:        100,
						bytesdownloaded: 10000000,
						bytesuploaded:   500,
						totalerrorrate:  1,
						fourxxerrorrate: 1,
						fivexxerrorrate: 1,
					},

					"dist-2": {
						requests:        200,
						bytesdownloaded: 20000000,
						bytesuploaded:   5000,
						totalerrorrate:  8,
						fourxxerrorrate: 7,
						fivexxerrorrate: 6,
					},
				}

				m := cases[aws.StringValue(input.Dimensions[0].Value)]

				output.Label = input.MetricName
				switch aws.StringValue(input.MetricName) {
				case "Requests":
					output.Datapoints = []*cloudwatch.Datapoint{
						{
							Sum:       aws.Float64(m.requests),
							Unit:      aws.String("None"),
							Timestamp: aws.Time(time.Now()),
						},
					}

				case "BytesDownloaded":
					output.Datapoints = []*cloudwatch.Datapoint{
						{
							Sum:       aws.Float64(m.bytesdownloaded),
							Unit:      aws.String("None"),
							Timestamp: aws.Time(time.Now()),
						},
					}

				case "BytesUploaded":
					output.Datapoints = []*cloudwatch.Datapoint{
						{
							Sum:       aws.Float64(m.bytesuploaded),
							Unit:      aws.String("None"),
							Timestamp: aws.Time(time.Now()),
						},
					}

				case "TotalErrorRate":
					output.Datapoints = []*cloudwatch.Datapoint{
						{
							Average:   aws.Float64(m.totalerrorrate),
							Unit:      aws.String("Percent"),
							Timestamp: aws.Time(time.Now()),
						},
					}

				case "4xxErrorRate":
					output.Datapoints = []*cloudwatch.Datapoint{
						{
							Average:   aws.Float64(m.fourxxerrorrate),
							Unit:      aws.String("Percent"),
							Timestamp: aws.Time(time.Now()),
						},
					}

				case "5xxErrorRate":
					output.Datapoints = []*cloudwatch.Datapoint{
						{
							Average:   aws.Float64(m.fivexxerrorrate),
							Unit:      aws.String("Percent"),
							Timestamp: aws.Time(time.Now()),
						},
					}
				}

				return &output, nil
			},
		)

		cloudwatchService = CloudWatchService{
			Client: &cloudwatchFake,
			Logger: logger,
		}
	})

	Context("with a single distribution", func() {
		It("returns the 6 metrics for the cloudfront distribution", func() {

			cloudFrontStub := CloudFrontServiceStub{
				domains: []CustomDomain{
					CustomDomain{
						CloudFrontDomain: "foo.bar.cloudapps.digital",
						AliasDomain:      "foo.bar.gov.uk",
						DistributionId:   "dist-1",
					},
				},
			}

			reader := CustomDomainCDNMetricsCollector(logger, &cloudFrontStub, cloudwatchService, 15*time.Second)
			defer reader.Close()

			var metrics []Metric
			Eventually(func() int {
				metric, err := reader.ReadMetric()
				if err == nil {
					metrics = append(metrics, metric)
				}
				return len(metrics)
			}, 3*time.Second).Should(BeNumerically(">=", 6))


			var metricNames []string
			for _, m := range metrics {
				metricNames = append(metricNames, m.Name)
			}

			Expect(metricNames).To(ContainElement("aws_cloudfront_requests"))
			Expect(metricNames).To(ContainElement("aws_cloudfront_bytesdownloaded"))
			Expect(metricNames).To(ContainElement("aws_cloudfront_bytesuploaded"))
			Expect(metricNames).To(ContainElement("aws_cloudfront_totalerrorrate"))
			Expect(metricNames).To(ContainElement("aws_cloudfront_4xxerrorrate"))
			Expect(metricNames).To(ContainElement("aws_cloudfront_5xxerrorrate"))
		})

		It("tags the 6 metrics with the distribution id", func() {

			cloudFrontStub := CloudFrontServiceStub{
				domains: []CustomDomain{
					CustomDomain{
						CloudFrontDomain: "foo.bar.cloudapps.digital",
						AliasDomain:      "foo.bar.gov.uk",
						DistributionId:   "dist-1",
					},
				},
			}

			reader := CustomDomainCDNMetricsCollector(logger, &cloudFrontStub, cloudwatchService, 15*time.Second)
			defer reader.Close()

			var metrics []Metric
			Eventually(func() int {
				metric, err := reader.ReadMetric()
				if err == nil {
					metrics = append(metrics, metric)
				}
				return len(metrics)
			}, 3*time.Second).Should(BeNumerically(">=", 6))

			expected := fmt.Sprintf("distribution_id:%s", "dist-1")
			Expect(metrics[0].Tags).To(ContainElement(expected))
			Expect(metrics[1].Tags).To(ContainElement(expected))
			Expect(metrics[2].Tags).To(ContainElement(expected))
			Expect(metrics[3].Tags).To(ContainElement(expected))
			Expect(metrics[4].Tags).To(ContainElement(expected))
			Expect(metrics[5].Tags).To(ContainElement(expected))
		})
	})

	Context("with 2 or more distribution", func() {
		It("returns the 6 metrics per cloudfront distribution", func() {
			cloudFrontStub := CloudFrontServiceStub{
				domains: []CustomDomain{
					CustomDomain{
						CloudFrontDomain: "foo.bar.cloudapps.digital",
						AliasDomain:      "foo.bar.gov.uk",
						DistributionId:   "dist-1",
					},

					CustomDomain{
						CloudFrontDomain: "bar.baz.cloudapps.digital",
						AliasDomain:      "bar.baz.gov.uk",
						DistributionId:   "dist-2",
					},
				},
			}

			reader := CustomDomainCDNMetricsCollector(logger, &cloudFrontStub, cloudwatchService, 15*time.Second)
			defer reader.Close()

			var metrics []Metric
			Eventually(func() int {
				metric, err := reader.ReadMetric()
				if err == nil {
					metrics = append(metrics, metric)
				}
				return len(metrics)
			}, 3*time.Second).Should(BeNumerically(">=", 12))
		})
	})
})
