package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("CDN broker", func() {
	It("should return CDN TLS cert metrics", func() {
		Skip("Exporter does not always return these metrics, service dependent")

		Eventually(getMetricNames).Should(SatisfyAll(
			ContainElement("paas_cdn_tls_certificates_expiry_days"),
			ContainElement("paas_cdn_tls_certificates_validity"),
		))
	})
})
