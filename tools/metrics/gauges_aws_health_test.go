package main_test

import (
	"code.cloudfoundry.org/lager"
	"errors"
	. "github.com/alphagov/paas-cf/tools/metrics"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"
	"time"

	healthfakes "github.com/alphagov/paas-cf/tools/metrics/pkg/health/fakes"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("AWS Health Gauge", func() {
	var (
		healthService healthfakes.FakeHealthServiceInterface
		logger        lager.Logger
	)

	BeforeEach(func() {
		healthService = healthfakes.FakeHealthServiceInterface{}
		logger = lager.NewLogger("aws-health-gauge")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.INFO))
	})

	It("exposes metrics with a service label", func() {
		healthService.CountOpenEventsForServiceInRegionReturns(2, nil)

		gauge := AWSHealthEventsGauge(logger, "eu-west-1", &healthService, 1 * time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3 * time.Second).Should(Equal("aws.health.active.events"))

		Expect(metric.Kind).To(Equal(m.Gauge))
		Expect(metric.Tags).To(ContainElement(
			MatchFields(
				IgnoreExtras,
				Fields{ "Label": Equal("service") }),
			),
		)
	})

	It("exposes metric with a value of 0 if there are no open events for a service", func() {
		healthService.CountOpenEventsForServiceInRegionReturns(0, nil)

		gauge := AWSHealthEventsGauge(logger, "eu-west-1", &healthService, 1 * time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3 * time.Second).Should(Equal("aws.health.active.events"))

		Expect(metric.Value).To(Equal(float64(0)))
	})

	It("exposes metric with a value > 0 if there open events for a service", func() {
		healthService.CountOpenEventsForServiceInRegionReturns(3, nil)

		gauge := AWSHealthEventsGauge(logger, "eu-west-1", &healthService, 1 * time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() string {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			return metric.Name
		}, 3 * time.Second).Should(Equal("aws.health.active.events"))

		Expect(metric.Value).To(Equal(float64(3)))
	})

	It("exposes no metrics when an error occurs", func() {
		healthService.CountOpenEventsForServiceInRegionReturns(-1, errors.New("whoops"))

		gauge := AWSHealthEventsGauge(logger, "eu-west-1", &healthService, 1 * time.Second)
		defer gauge.Close()

		Consistently(func() *m.Metric {
			var err error
			possibleMetric, err := gauge.ReadMetric()
			Expect(err).To(HaveOccurred())

			if err != nil {
				return nil
			}
			return &possibleMetric
		}, 3 * time.Second).Should(BeNil())
	})
})
