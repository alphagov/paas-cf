package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Currency", func() {
	It("should return currency metrics", func() {
		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_currency_real"),
			HaveKey("paas_currency_configured"),
		))
	})
})
