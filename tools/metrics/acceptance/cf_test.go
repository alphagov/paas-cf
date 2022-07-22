package acceptance

import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Cloud Foundry", func() {
	It("should return CF quota metrics", func() {
		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_op_quota_memory_allocated_megabytes"),
			ContainElement("paas_op_quota_memory_reserved_megabytes"),
			ContainElement("paas_op_quota_routes_reserved_count"),
			ContainElement("paas_op_quota_services_allocated_count"),
			ContainElement("paas_op_quota_services_reserved_count"),
		))
	})

	It("should return CF application metrics", func() {
		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_op_apps_count"),
			ContainElement("paas_op_events_app_crash_count"),
		))
	})

	It("should return CF org metrics", func() {
		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_op_orgs_count"),
			ContainElement("paas_op_spaces_count"),
			ContainElement("paas_op_services_provisioned_count"),
			ContainElement("paas_op_users_count"),
		))
	})

	It("should return CF service metrics", func() {
		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_op_services_provisioned_count"),
			ContainElement("paas_op_users_count"),
		))
	})

	It("should return CF user metrics", func() {
		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_op_users_count"),
		))
	})
})
