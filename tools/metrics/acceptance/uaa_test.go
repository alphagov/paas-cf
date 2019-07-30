package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("UAA", func() {
	It("should return UAA user metrics", func() {
		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_uaa_users_count"),
			HaveKey("paas_uaa_active_users_count"),
		))
	})
})
