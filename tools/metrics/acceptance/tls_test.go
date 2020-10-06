package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("TLS =", func() {
	It("should return TLS cert metrics", func() {
		Eventually(getMetrics).Should(SatisfyAll(
			HaveKey("paas_tls_certificates_validity_days"),
		))
	})
})
