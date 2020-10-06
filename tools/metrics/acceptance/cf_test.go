package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Cloud Foundry", func() {
	It("should return CF quota metrics", func() {
		Eventually(getMetrics).Should(SatisfyAll(
			HaveKey("paas_op_quota_memory_allocated_megabytes"),
			HaveKey("paas_op_quota_memory_reserved_megabytes"),
			HaveKey("paas_op_quota_routes_reserved_count"),
			HaveKey("paas_op_quota_services_allocated_count"),
			HaveKey("paas_op_quota_services_reserved_count"),
		))
	})

	It("should return CF application metrics", func() {
		Eventually(getMetrics).Should(SatisfyAll(
			HaveKey("paas_op_apps_count"),
			HaveKey("paas_op_events_app_crash_count"),
		))
	})

	It("should return CF org metrics", func() {
		Eventually(getMetrics).Should(SatisfyAll(
			HaveKey("paas_op_orgs_count"),
			HaveKey("paas_op_spaces_count"),
			HaveKey("paas_op_services_provisioned_count"),
			HaveKey("paas_op_users_count"),
		))
	})

	It("should return CF service metrics", func() {
		Eventually(getMetrics).Should(SatisfyAll(
			HaveKey("paas_op_services_provisioned_count"),
			HaveKey("paas_op_users_count"),
		))
	})

	It("should return CF user metrics", func() {
		Eventually(getMetrics).Should(SatisfyAll(
			HaveKey("paas_op_users_count"),
		))
	})
})
