package main_test

import (
	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/shield/fakes"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	"time"
)

var _ = Describe("ShieldOngoingAttacksGauge", func() {
	var (
		logger lager.Logger
	)

	BeforeEach(func() {
		logger = lager.NewLogger("shield-ongoing-attacks-gauge-test")
		logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.INFO))
	})

	It("emits a single metric: the count of the number of attacks", func() {
		fakeShieldService := fakes.FakeShieldServiceInterface{}
		fakeShieldService.CountOnGoingAttacksReturns(2, nil)

		gauge := ShieldOngoingAttacksGauge(logger, &fakeShieldService, 1*time.Second)
		defer gauge.Close()

		var metric m.Metric
		Eventually(func() float64 {
			var err error
			metric, err = gauge.ReadMetric()
			Expect(err).ToNot(HaveOccurred())
			return metric.Value
		}).Should(Equal(float64(2)))
	})
})
