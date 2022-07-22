package main_test

import (
	"crypto/tls"
	"errors"
	"fmt"
	"time"

	"code.cloudfoundry.org/lager"
	"github.com/aws/aws-sdk-go/aws"
	awscf "github.com/aws/aws-sdk-go/service/cloudfront"

	. "github.com/alphagov/paas-cf/tools/metrics"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/cloudfront/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	tlscheck_fakes "github.com/alphagov/paas-cf/tools/metrics/pkg/tlscheck/fakes"
)

func ExpectMetric(metric m.Metric, name string, value int, host string) {
	Expect(metric.Name).To(Equal(name))
	Expect(metric.Value).To(Equal(float64(value)))
	Expect(metric.Kind).To(Equal(m.Gauge))

	expectedTag := m.MetricTag{Label: "hostname", Value: host}
	Expect(metric.Tags).To(ContainElement(expectedTag))
}

var _ = Describe("TLS gauges", func() {

	var (
		logger            lager.Logger
		log               *gbytes.Buffer
		tlsChecker        *tlscheck_fakes.FakeCertChecker
		cloudFrontService *cloudfront.CloudFrontService
		cloudFrontClient  *fakes.FakeCloudFrontAPI

		distributionSummaries = []*awscf.DistributionSummary{
			&awscf.DistributionSummary{
				Enabled:    aws.Bool(true),
				DomainName: aws.String("d1.cloudfront.aws"),
				Id:         aws.String("dist-1"),
				Aliases: &awscf.Aliases{
					Quantity: aws.Int64(2),
					Items: []*string{
						aws.String("s1.service.gov.uk"),
					},
				},
			},
			&awscf.DistributionSummary{
				Enabled:    aws.Bool(true),
				DomainName: aws.String("d2.cloudfront.aws"),
				Id:         aws.String("dist-2"),
				Aliases: &awscf.Aliases{
					Quantity: aws.Int64(2),
					Items: []*string{
						aws.String("s2.service.gov.uk"),
						aws.String("s3.service.gov.uk"),
					},
				},
			},
		}
		listDistributionsPageStub = func(
			input *awscf.ListDistributionsInput,
			fn func(*awscf.ListDistributionsOutput, bool) bool,
		) error {
			for i, distributionSummary := range distributionSummaries {
				page := &awscf.ListDistributionsOutput{
					DistributionList: &awscf.DistributionList{
						Items: []*awscf.DistributionSummary{
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
		cloudFrontService = &cloudfront.CloudFrontService{Client: cloudFrontClient}
	})

	Describe("TLS validity gauge", func() {

		Context("If certificate is valid", func() {
			It("returns the expiry in days", func() {
				tlsChecker.DaysUntilExpiryReturnsOnCall(0, float64(123), nil)

				gauge := TLSValidityGauge(logger, tlsChecker, "somedomain.com:443", 1*time.Second)
				defer gauge.Close()

				var metric m.Metric
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

				var metric m.Metric
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

				var metric m.Metric
				Eventually(func() error {
					var err error
					metric, err = gauge.ReadMetric()
					return err
				}, 3*time.Second).ShouldNot(HaveOccurred())
				Expect(metric.Value).To(Equal(float64(123)))

				expectedTag := m.MetricTag{Label: "hostname", Value: "somedomain.com"}
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

			var metrics []m.Metric
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

				var metrics []m.Metric
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

	Describe("CDN TLS certificate authority gauge", func() {
		It("counts the number of certificates per certificate authority", func() {
			cloudFrontClient.ListDistributionsPagesStub = listDistributionsPageStub
			tlsChecker.CertificateAuthorityCalls(func(_ string, tlsConfig *tls.Config) (string, error) {
				switch tlsConfig.ServerName {
				case "s1.service.gov.uk":
					return "Amazon", nil

				case "s2.service.gov.uk", "s3.service.gov.uk":
					return "Let's Encrypt", nil

				default:
					return "", fmt.Errorf("unexpected domain: %s", tlsConfig.ServerName)
				}
			})

			gauge := CDNTLSCertificateAuthorityGauge(logger, tlsChecker, cloudFrontService, 1*time.Second)
			defer gauge.Close()

			var metrics []m.Metric
			Eventually(func() int {
				metric, _ := gauge.ReadMetric()
				metrics = append(metrics, metric)
				return len(metrics)
			}, 3*time.Second).Should(Equal(2))

			var amazonMetric *m.Metric
			var letsEncryptMetric *m.Metric

			for i, metric := range metrics {
				for _, tag := range metric.Tags {
					if tag.Label == "certificate_authority" {
						switch tag.Value {
						case "Amazon":
							amazonMetric = &metrics[i]
						case "Let's Encrypt":
							letsEncryptMetric = &metrics[i]
						}
					}
				}
			}

			Expect(amazonMetric).ToNot(BeNil(), "Amazon CA metric was not found")
			Expect(letsEncryptMetric).ToNot(BeNil(), "Let's Encrypt CA metric was not found")
			Expect(amazonMetric.Value).To(Equal(float64(1)))
			Expect(letsEncryptMetric.Value).To(Equal(float64(2)))
		})
	})

})
