package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("UAA", func() {
	It("should return UAA user metrics", func() {
		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_uaa_users_count"),
			ContainElement("paas_uaa_active_users_count"),
		))
	})
})
