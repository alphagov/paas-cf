package main

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gstruct"

	"code.cloudfoundry.org/lager"
	"github.com/jarcoal/httpmock"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("Currency", func() {
	logger := lager.NewLogger("currency")
	logger.RegisterSink(lager.NewWriterSink(gbytes.NewBuffer(), lager.INFO))

	BeforeEach(func() {
		httpmock.Activate()
	})

	AfterEach(func() {
		httpmock.DeactivateAndReset()
	})

	Context("European Central Bank API", func() {
		It("Should gracefully return an error when the request is bad", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://api.exchangeratesapi.io/latest\z`,
				httpmock.NewStringResponder(400, ``),
			)

			rate, err := getCurrencyFromECB("USD", "BADCURRENCY")

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).To(HaveOccurred())
			Expect(err).To(MatchError(ContainSubstring(
				"Did not receive HTTP 200 OK",
			)))

			Expect(rate).To(BeNumerically("==", 0))
		})
	})

	It("Should gracefully return an error when the response is bad", func() {
		httpmock.RegisterResponder(
			"GET", `=~^https://api.exchangeratesapi.io/latest\z`,
			httpmock.NewStringResponder(200, `{not-well-formatted-json}`),
		)

		rate, err := getCurrencyFromECB("USD", "GBP")

		Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

		Expect(err).To(HaveOccurred())
		Expect(err).To(MatchError(ContainSubstring(
			"Could not unmarshal response from ECB",
		)))

		Expect(rate).To(BeNumerically("==", 0))
	})

	It("Should gracefully return an error when the target is not found", func() {
		httpmock.RegisterResponder(
			"GET", `=~^https://api.exchangeratesapi.io/latest\z`,
			httpmock.NewStringResponder(200, `{"rates": {}}`),
		)

		rate, err := getCurrencyFromECB("USD", "GBP")

		Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

		Expect(err).To(HaveOccurred())
		Expect(err).To(MatchError(ContainSubstring(
			"Could not find target",
		)))

		Expect(rate).To(BeNumerically("==", 0))
	})

	It("Should return the rate correctly", func() {
		httpmock.RegisterResponder(
			"GET", `=~^https://api.exchangeratesapi.io/latest\z`,
			httpmock.NewStringResponder(200, `{"rates": {"GBP": 0.8}}`),
		)

		rate, err := getCurrencyFromECB("USD", "GBP")

		Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

		Expect(err).NotTo(HaveOccurred())

		Expect(rate).To(BeNumerically("==", 0.8))
	})

	Context("CurrencyMetricGauges", func() {
		It("Should handle errors gracefully", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://api.exchangeratesapi.io/latest\z`,
				httpmock.NewStringResponder(404, ``),
			)

			_, err := CurrencyMetricGauges(logger)

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).To(HaveOccurred())
			Expect(err).To(MatchError(ContainSubstring(
				"Did not receive HTTP 200 OK",
			)))
		})

		It("Should return the configured and the live value correctly", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://api.exchangeratesapi.io/latest\z`,
				httpmock.NewStringResponder(200, `{"rates": {"GBP": 0.8}}`),
			)

			metrics, err := CurrencyMetricGauges(logger)

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).NotTo(HaveOccurred())

			Expect(metrics).To(HaveLen(1))

			Expect(metrics).To(ContainElement(MatchFields(IgnoreExtras, Fields{
				"Name":  Equal("currency.real"),
				"Unit":  Equal("ratio"),
				"Kind":  Equal(m.Gauge),
				"Value": BeNumerically("==", 0.8),
				"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
					"Label": Equal("code"), "Value": Equal("USD"),
				})),
			})))
		})
	})
})
