package main_test

import (
	"crypto/tls"
	"errors"
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/fakes"
	tlscheck_fakes "github.com/alphagov/paas-cf/tools/metrics/tlscheck/fakes"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudfront"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
)

func ExpectMetric(metric Metric, name string, value int, host string) {
	Expect(metric.Name).To(Equal(name))
	Expect(metric.Value).To(Equal(float64(value)))
	Expect(metric.Kind).To(Equal(Gauge))


	expectedTag := MetricTag { Label: "hostname", Value: host }
	Expect(metric.Tags).To(ContainElement(expectedTag))
}

var _ = Describe("TLS gauges", func() {

	var (
		logger            lager.Logger
		log               *gbytes.Buffer
		tlsChecker        *tlscheck_fakes.FakeCertChecker
		cloudFrontService *CloudFrontService
		cloudFrontClient  *fakes.FakeCloudFrontAPI

		distributionSummaries = []*cloudfront.DistributionSummary{
			&cloudfront.DistributionSummary{
				Enabled:    aws.Bool(true),
				DomainName: aws.String("d1.cloudfront.aws"),
				Id: aws.String("dist-1"),
				Aliases: &cloudfront.Aliases{
					Quantity: aws.Int64(2),
					Items: []*string{
						aws.String("s1.service.gov.uk"),
					},
				},
			},
			&cloudfront.DistributionSummary{
				Enabled:    aws.Bool(true),
				DomainName: aws.String("d2.cloudfront.aws"),
				Id: aws.String("dist-2"),
				Aliases: &cloudfront.Aliases{
					Quantity: aws.Int64(2),
					Items: []*string{
						aws.String("s2.service.gov.uk"),
						aws.String("s3.service.gov.uk"),
					},
				},
			},
		}
		listDistributionsPageStub = func(
			input *cloudfront.ListDistributionsInput,
			fn func(*cloudfront.ListDistributionsOutput, bool) bool,
		) error {
			for i, distributionSummary := range distributionSummaries {
				page := &cloudfront.ListDistributionsOutput{
					DistributionList: &cloudfront.DistributionList{
						Items: []*cloudfront.DistributionSummary{
							distributionSummary,
						},
					},
				}
				if !fn(page, i+1 >= len(distributionSummaries)) {
					break
				}
			}
			return nil
		}
	)

	BeforeEach(func() {
		logger = lager.NewLogger("logger")
		log = gbytes.NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(log, lager.INFO))
		tlsChecker = &tlscheck_fakes.FakeCertChecker{}
		cloudFrontClient = &fakes.FakeCloudFrontAPI{}
		cloudFrontService = &CloudFrontService{Client: cloudFrontClient}
	})

	Describe("TLS validity gauge", func() {

		Context("If certificate is valid", func() {
			It("returns the expiry in days", func() {
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(123), nil)

				gauge := TLSValidityGauge(logger, tlsChecker, "somedomain.com:443", 1*time.Second)
				defer gauge.Close()

				var metric Metric
				Eventually(func() error {
					var err error
					metric, err = gauge.ReadMetric()
					return err
				}, 3*time.Second).ShouldNot(HaveOccurred())

				ExpectMetric(metric, "tls.certificates.validity", 123, "somedomain.com")

				passedDomain, passedTLSConfig := tlsChecker.DaysUntilExpiryArgsForCall(0)
				Expect(passedDomain).To(Equal("somedomain.com:443"))
				Expect(passedTLSConfig).To(Equal(&tls.Config{}))
			})
		})

		Context("If certificate has expired", func() {
			It("returns the metric with zero value", func() {
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(0), nil)

				gauge := TLSValidityGauge(logger, tlsChecker, "somedomain.com:443", 1*time.Second)
				defer gauge.Close()

				var metric Metric
				Eventually(func() error {
					var err error
					metric, err = gauge.ReadMetric()
					return err
				}, 3*time.Second).ShouldNot(HaveOccurred())
				Expect(metric.Value).To(Equal(float64(0)))
			})
		})

		Context("If certificate check returns an error", func() {
			It("returns the error", func() {
				metricErr := errors.New("some error")
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(0), metricErr)

				gauge := TLSValidityGauge(logger, tlsChecker, "somedomain.com:443", 5*time.Second)
				defer gauge.Close()

				Eventually(func() error {
					metric, err := gauge.ReadMetric()
					fmt.Fprintln(GinkgoWriter, metric, err)
					return err
				}, 3*time.Second).Should(MatchError(metricErr))
			})
		})

		Context("If hostname doesn't have a port", func() {
			It("adds :443 by default", func() {
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(123), nil)

				gauge := TLSValidityGauge(logger, tlsChecker, "somedomain.com", 1*time.Second)
				defer gauge.Close()

				var metric Metric
				Eventually(func() error {
					var err error
					metric, err = gauge.ReadMetric()
					return err
				}, 3*time.Second).ShouldNot(HaveOccurred())
				Expect(metric.Value).To(Equal(float64(123)))

				expectedTag := MetricTag{ Label: "hostname", Value: "somedomain.com"}
				Expect(metric.Tags).To(ContainElement(expectedTag))
			})
		})

		Context("Hostname is invalid", func() {
			It("returns an error", func() {
				gauge := TLSValidityGauge(logger, tlsChecker, "hostname[", 1*time.Second)
				defer gauge.Close()

				Eventually(func() error {
					metric, err := gauge.ReadMetric()
					fmt.Fprintln(GinkgoWriter, metric, err)
					return err
				}, 3*time.Second).Should(HaveOccurred())
			})
		})

	})

	Describe("CDN TLS validity gauge", func() {

		It("returns the expiration dates for all CloudFront domains", func() {
			cloudFrontClient.ListDistributionsPagesStub = listDistributionsPageStub

			tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(123), nil)
			tlsChecker.DaysUntilExpiryReturnsOnCall(1, float64(234), nil)
			tlsChecker.DaysUntilExpiryReturnsOnCall(2, float64(345), nil)

			gauge := CDNTLSValidityGauge(logger, tlsChecker, cloudFrontService, 1*time.Second)
			defer gauge.Close()

			var metrics []Metric
			Eventually(func() int {
				metric, _ := gauge.ReadMetric()
				metrics = append(metrics, metric)
				return len(metrics)
			}, 3*time.Second).Should(Equal(6))

			ExpectMetric(metrics[0], "cdn.tls.certificates.expiry", 123, "s1.service.gov.uk")
			ExpectMetric(metrics[1], "cdn.tls.certificates.validity", 1, "s1.service.gov.uk")
			ExpectMetric(metrics[2], "cdn.tls.certificates.expiry", 234, "s2.service.gov.uk")
			ExpectMetric(metrics[3], "cdn.tls.certificates.validity", 1, "s2.service.gov.uk")
			ExpectMetric(metrics[4], "cdn.tls.certificates.expiry", 345, "s3.service.gov.uk")
			ExpectMetric(metrics[5], "cdn.tls.certificates.validity", 1, "s3.service.gov.uk")

			Expect(tlsChecker.DaysUntilExpiryCallCount()).To(Equal(3))
			passedDomain, passedTLSConfig := tlsChecker.DaysUntilExpiryArgsForCall(0)
			Expect(passedDomain).To(Equal("d1.cloudfront.aws:443"))
			Expect(passedTLSConfig).To(Equal(&tls.Config{
				ServerName: "s1.service.gov.uk",
			}))

			passedDomain, passedTLSConfig = tlsChecker.DaysUntilExpiryArgsForCall(1)
			Expect(passedDomain).To(Equal("d2.cloudfront.aws:443"))
			Expect(passedTLSConfig).To(Equal(&tls.Config{
				ServerName: "s2.service.gov.uk",
			}))

			passedDomain, passedTLSConfig = tlsChecker.DaysUntilExpiryArgsForCall(2)
			Expect(passedDomain).To(Equal("d2.cloudfront.aws:443"))
			Expect(passedTLSConfig).To(Equal(&tls.Config{
				ServerName: "s3.service.gov.uk",
			}))
		})

		Context("If the CloudFront service returns an error", func() {
			It("returns the error", func() {
				apiError := errors.New("some error")
				cloudFrontClient.ListDistributionsPagesReturnsOnCall(0, apiError)

				gauge := CDNTLSValidityGauge(logger, tlsChecker, cloudFrontService, 5*time.Second)
				defer gauge.Close()

				Eventually(func() error {
					metric, err := gauge.ReadMetric()
					fmt.Fprintln(GinkgoWriter, metric, err)
					return err
				}, 3*time.Second).Should(MatchError(apiError))
			})
		})

		Context("If the TLS check returns an error for any of the domains", func() {
			It("doesn't report a metric for that domain", func() {
				cloudFrontClient.ListDistributionsPagesStub = listDistributionsPageStub

				tlsErr := errors.New("some error")
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(0), tlsErr)
				tlsChecker.DaysUntilExpiryReturnsOnCall(1, float64(234), nil)
				tlsChecker.DaysUntilExpiryReturnsOnCall(2, float64(345), nil)

				gauge := CDNTLSValidityGauge(logger, tlsChecker, cloudFrontService, 5*time.Second)
				defer gauge.Close()

				var metrics []Metric
				Eventually(func() int {
					metric, err := gauge.ReadMetric()
					if err == nil {
						metrics = append(metrics, metric)
					}
					return len(metrics)
				}, 3*time.Second).Should(BeNumerically(">=", 5))

				Expect(tlsChecker.DaysUntilExpiryCallCount()).To(Equal(3))

				ExpectMetric(metrics[0], "cdn.tls.certificates.validity", 0, "s1.service.gov.uk")
				ExpectMetric(metrics[1], "cdn.tls.certificates.expiry", 234, "s2.service.gov.uk")
				ExpectMetric(metrics[2], "cdn.tls.certificates.validity", 1, "s2.service.gov.uk")
				ExpectMetric(metrics[3], "cdn.tls.certificates.expiry", 345, "s3.service.gov.uk")
				ExpectMetric(metrics[4], "cdn.tls.certificates.validity", 1, "s3.service.gov.uk")
			})
		})

	})

})
