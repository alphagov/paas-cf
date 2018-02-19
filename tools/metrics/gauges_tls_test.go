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
				Expect(metric.Name).To(Equal("tls.certificates.validity"))
				Expect(metric.Value).To(Equal(float64(123)))
				Expect(metric.Kind).To(Equal(Gauge))
				Expect(metric.Tags).To(Equal([]string{
					fmt.Sprintf("hostname:somedomain.com"),
				}))

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
				Expect(metric.Tags).To(Equal([]string{
					fmt.Sprintf("hostname:somedomain.com"),
				}))
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
			}, 3*time.Second).Should(Equal(3))

			Expect(metrics[0].Name).To(Equal("cdn.tls.certificates.validity"))
			Expect(metrics[0].Value).To(Equal(float64(123)))
			Expect(metrics[0].Kind).To(Equal(Gauge))
			Expect(metrics[0].Tags).To(Equal([]string{
				fmt.Sprintf("hostname:s1.service.gov.uk"),
			}))

			Expect(metrics[1].Name).To(Equal("cdn.tls.certificates.validity"))
			Expect(metrics[1].Value).To(Equal(float64(234)))
			Expect(metrics[1].Kind).To(Equal(Gauge))
			Expect(metrics[1].Tags).To(Equal([]string{
				fmt.Sprintf("hostname:s2.service.gov.uk"),
			}))

			Expect(metrics[2].Name).To(Equal("cdn.tls.certificates.validity"))
			Expect(metrics[2].Value).To(Equal(float64(345)))
			Expect(metrics[2].Kind).To(Equal(Gauge))
			Expect(metrics[2].Tags).To(Equal([]string{
				fmt.Sprintf("hostname:s3.service.gov.uk"),
			}))

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
			It("returns the error", func() {
				cloudFrontClient.ListDistributionsPagesStub = listDistributionsPageStub
				tlsErr := errors.New("some error")
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(123), nil)
				tlsChecker.DaysUntilExpiryReturnsOnCall(1, float64(0), tlsErr)

				gauge := CDNTLSValidityGauge(logger, tlsChecker, cloudFrontService, 1*time.Second)
				defer gauge.Close()

				Eventually(func() error {
					metric, err := gauge.ReadMetric()
					fmt.Fprintln(GinkgoWriter, metric, err)
					return err
				}, 3*time.Second).Should(MatchError(tlsErr))
			})
		})

	})

})
