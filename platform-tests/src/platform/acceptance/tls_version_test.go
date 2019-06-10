package acceptance_test

import (
	"crypto/tls"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Checking the TLS version", func() {
	testHostPortGetters := map[string]func() string{
		"apps_apex": func() string {
			return testConfig.GetAppsDomain() + ":443"
		},
		"apps": func() string {
			return "healthcheck." + testConfig.GetAppsDomain() + ":443"
		},
		"system": func() string {
			return testConfig.GetApiEndpoint() + ":443"
		},
		"doppler": func() string {
			return "doppler." + GetConfigFromEnvironment("SYSTEM_DNS_ZONE_NAME") + ":443"
		},
		"concourse": func() string {
			return "deployer." + GetConfigFromEnvironment("SYSTEM_DNS_ZONE_NAME") + ":443"
		},
	}

	for domainClass, hostPortGetter := range testHostPortGetters {
		domainClass, hostPortGetter := domainClass, hostPortGetter

		Context(domainClass+" domain", func() {
			It("should not allow SSL 3.0", func() {
				tlsConfig := &tls.Config{
					MinVersion: tls.VersionSSL30,
					MaxVersion: tls.VersionSSL30,
				}
				hostPort := hostPortGetter()
				conn, err := tls.Dial("tcp", hostPort, tlsConfig)
				if err == nil {
					defer conn.Close()
				}
				Expect(err).To(HaveOccurred())
				Expect(err).To(SatisfyAny(
					MatchError("tls: no supported versions satisfy MinVersion and MaxVersion"),
					MatchError("EOF"),
				))
			})
			It("should not allow TLS 1.0", func() {
				tlsConfig := &tls.Config{
					MinVersion: tls.VersionTLS10,
					MaxVersion: tls.VersionTLS10,
				}
				hostPort := hostPortGetter()
				conn, err := tls.Dial("tcp", hostPort, tlsConfig)
				if err == nil {
					defer conn.Close()
				}
				Expect(err).To(HaveOccurred())
				Expect(err).To(SatisfyAny(
					MatchError("tls: no supported versions satisfy MinVersion and MaxVersion"),
					MatchError("EOF"),
				))
			})
			It("should not allow TLS 1.1", func() {
				tlsConfig := &tls.Config{
					MinVersion: tls.VersionTLS11,
					MaxVersion: tls.VersionTLS11,
				}
				hostPort := hostPortGetter()
				conn, err := tls.Dial("tcp", hostPort, tlsConfig)
				if err == nil {
					defer conn.Close()
				}
				Expect(err).To(HaveOccurred())
				Expect(err).To(SatisfyAny(
					MatchError("tls: no supported versions satisfy MinVersion and MaxVersion"),
					MatchError("EOF"),
				))
			})

			It("should allow TLS 1.2", func() {
				tlsConfig := &tls.Config{
					MinVersion: tls.VersionTLS12,
					MaxVersion: tls.VersionTLS12,
				}
				hostPort := hostPortGetter()
				conn, err := tls.Dial("tcp", hostPort, tlsConfig)
				if err == nil {
					defer conn.Close()
				}
				Expect(err).ToNot(HaveOccurred())
			})
		})
	}

})
