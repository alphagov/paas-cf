package acceptance_test

import (
	"crypto/tls"
	"net"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("The apps apex domain", func() {

	It("should have the same DNS records as the healthcheck app", func() {
		apexIPs, err := net.LookupIP(testConfig.GetAppsDomain())
		Expect(err).NotTo(HaveOccurred())
		healthcheckIPs, err := net.LookupIP("healthcheck." + testConfig.GetAppsDomain())
		Expect(err).NotTo(HaveOccurred())
		Expect(apexIPs).To(ConsistOf(healthcheckIPs))
	})

	It("should have a valid TLS certificate with the apps domain as SAN", func() {
		conn, err := tls.Dial("tcp", testConfig.GetAppsDomain()+":443", nil)
		Expect(err).NotTo(HaveOccurred())
		defer conn.Close()
		peerCertificates := conn.ConnectionState().PeerCertificates
		Expect(len(peerCertificates)).To(BeNumerically(">", 0))
		cert := peerCertificates[0]
		Expect(cert.DNSNames).To(ContainElement(testConfig.GetAppsDomain()))
	})

})
