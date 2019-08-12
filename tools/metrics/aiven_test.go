package main

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"net/url"
	"time"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/aiven"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/aiven/fakes"
)

var _ = Describe("Aiven", func() {
	var (
		aivenClient     *aiven.Client
		fakeAivenServer *fakes.FakeAivenServer
	)

	BeforeEach(func() {
		var err error
		fakeAivenServer = fakes.NewFakeAivenServer("123456")
		aivenClient, err = aiven.NewClient("test", "123456")
		Expect(err).ToNot(HaveOccurred())
		aivenClient.BaseURL, err = url.Parse(fakeAivenServer.Server.URL)
		Expect(err).ToNot(HaveOccurred())

	})

	It("returns all invoices", func() {
		invoices, err := aivenClient.GetInvoices()
		Expect(err).ToNot(HaveOccurred())
		Expect(invoices).To(HaveLen(2))
	})

	It("returns error of auth token is invalid", func() {
		aivenClient.Token = "boaty mcboatface"
		_, err := aivenClient.GetInvoices()
		Expect(err).To(HaveOccurred())
	})

	Context("selects value from estimated invoice", func() {
		It("lists all custom domains", func() {
			gauge := AivenCostGauge(aivenClient, 1*time.Second)
			defer gauge.Close()
			var metric Metric
			Eventually(func() string {
				var err error
				metric, err = gauge.ReadMetric()
				Expect(err).NotTo(HaveOccurred())
				return metric.Name
			}, 3*time.Second).Should(Equal("aiven.estimated.cost"))

			Expect(metric.Value).To(Equal(10.88))
			Expect(metric.Kind).To(Equal(Gauge))
		})
	})
})
