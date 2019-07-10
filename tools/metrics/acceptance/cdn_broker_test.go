package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("CDN broker", func() {
	It("should return CDN TLS cert metrics", func() {
		Skip("Exporter does not always return these metrics, service dependent")

		Expect(metricFamilies).To(SatisfyAll(
			HaveKey("paas_cdn_tls_certificates_expiry_days"),
			HaveKey("paas_cdn_tls_certificates_validity"),
		))
	})
})
