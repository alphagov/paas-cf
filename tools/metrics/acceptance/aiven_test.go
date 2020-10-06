package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Aiven", func() {
	It("should return estimated cost", func() {
		Eventually(getMetricNames).Should(
			ContainElement("paas_aiven_estimated_cost_pounds"),
		)
	})
})
