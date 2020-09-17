package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Currency", func() {
	It("should return currency metrics", func() {
		Eventually(metricFamilies).Should(SatisfyAll(
			HaveKey("paas_currency_real_ratio"),
		))
	})
})
