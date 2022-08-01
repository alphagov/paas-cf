package acceptance_test

import (
	"crypto/tls"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

const (
	LB_TYPE_CLASSIC = "classic"
	LB_TYPE_ALB     = "ALB"
)

type tlsTestConfig struct {
	HostPortGetter   func() string
	LoadBalancerType string
}

func AssertTLSErrorOnClassicLB(err error) {
	Expect(err).To(HaveOccurred())
	Expect(err).To(SatisfyAny(
		MatchError("tls: no supported versions satisfy MinVersion and MaxVersion"),
		MatchError("tls: protocol version not supported"),
		MatchError("EOF"),
	))
}

func AssertTLSErrorOnALB(err error) {
	Expect(err).To(HaveOccurred())
	Expect(err.Error()).To(SatisfyAny(
		// An ALB will close the connection when trying to
		// connect with an unsupported version of TLS,
		ContainSubstring("read: connection reset by peer"),
		// but will return an error, which crypto/tls can
		// translate in to the below, when connecting with SSL.
		ContainSubstring("tls: no supported versions satisfy MinVersion and MaxVersion"),
		ContainSubstring("tls: protocol version not supported"),
	))
}

var _ = Describe("Checking the TLS version", func() {
	testHostPortGetters := map[string]tlsTestConfig{
		"apps_apex": {
			func() string {
				return testConfig.GetAppsDomain() + ":443"
			},
			LB_TYPE_CLASSIC,
		},
		"apps": {
			func() string {
				return "healthcheck." + testConfig.GetAppsDomain() + ":443"
			},
			LB_TYPE_CLASSIC,
		},
		"system": {
			func() string {
				return testConfig.GetApiEndpoint() + ":443"
			},
			LB_TYPE_CLASSIC,
		},
		"doppler": {
			func() string {
				return "doppler." + GetConfigFromEnvironment("SYSTEM_DNS_ZONE_NAME") + ":443"
			},
			LB_TYPE_ALB,
		},
		"concourse": {
			func() string {
				return "deployer." + GetConfigFromEnvironment("SYSTEM_DNS_ZONE_NAME") + ":443"
			},
			LB_TYPE_CLASSIC,
		},
	}

	for domainClass, testConfig := range testHostPortGetters {
		hostPortGetter := testConfig.HostPortGetter
		loadBalancerType := testConfig.LoadBalancerType

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

				switch loadBalancerType {
				case LB_TYPE_CLASSIC:
				default:
					AssertTLSErrorOnClassicLB(err)
					break

				case LB_TYPE_ALB:
					AssertTLSErrorOnALB(err)
					break
				}
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

				switch loadBalancerType {
				case LB_TYPE_CLASSIC:
				default:
					AssertTLSErrorOnClassicLB(err)
					break

				case LB_TYPE_ALB:
					AssertTLSErrorOnALB(err)
					break
				}
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

				switch loadBalancerType {
				case LB_TYPE_CLASSIC:
				default:
					AssertTLSErrorOnClassicLB(err)
					break

				case LB_TYPE_ALB:
					AssertTLSErrorOnALB(err)
					break
				}
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
