package main_test

import (
	"context"
	"net"
	"net/http"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/fakes"
	"github.com/alphagov/paas-cf/tools/metrics/pingdumb"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
)

var _ = Describe("Gauges", func() {

	var (
		resolvers []*net.Resolver
		server    *http.Server
		logger    lager.Logger
		log       *gbytes.Buffer
		records   = map[string][]string{
			"gauges.test.": []string{
				"127.0.0.1",
				"0.0.0.0",
			},
		}
	)

	BeforeSuite(func() {
		resolvers = []*net.Resolver{
			&net.Resolver{
				Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
					dialer := &net.Dialer{}
					return dialer.DialContext(ctx, network, "127.0.0.1:8553")
				},
			},
		}

		go func() {
			defer GinkgoRecover()
			Expect(fakes.ListenAndServeDNS(":8553", records)).To(Succeed())
		}()

		server = fakes.ListenAndServeHTTP(":8580")
	})

	AfterSuite(func() {
		fakes.ShutdownDNS()
		server.Close()
	})

	BeforeEach(func() {
		logger = lager.NewLogger("logger")
		log = gbytes.NewBuffer()
		logger.RegisterSink(lager.NewWriterSink(log, lager.INFO))
	})

	It("emits two metrics", func() {
		config := pingdumb.ReportConfig{
			Target:    "http://gauges.test:8580",
			Resolvers: resolvers,
			Timeout:   1 * time.Second,
		}
		gauge := ELBNodeFailureCountGauge(logger, config, 1*time.Second)
		metric, err := gauge.ReadMetric()
		Expect(err).NotTo(HaveOccurred())
		Expect(metric.Name).To(Equal("aws.elb.unhealthy_node_count"))
		Expect(metric.Value).To(Equal(float64(0)))

		metric, err = gauge.ReadMetric()
		Expect(err).NotTo(HaveOccurred())
		Expect(metric.Name).To(Equal("aws.elb.healthy_node_count"))
		numberOfAddrs := len(records["gauges.test."])
		Expect(metric.Value).To(Equal(float64(numberOfAddrs)))
	})

	It("returns failure count > 0 and logs failures", func() {
		config := pingdumb.ReportConfig{
			Target:    "http://gauges.test:7878",
			Resolvers: resolvers,
			Timeout:   1 * time.Second,
		}
		gauge := ELBNodeFailureCountGauge(logger, config, 1*time.Second)
		metric, err := gauge.ReadMetric()
		Expect(err).NotTo(HaveOccurred())
		Expect(metric.Name).To(Equal("aws.elb.unhealthy_node_count"))
		numberOfAddrs := len(records["gauges.test."])
		Expect(metric.Value).To(Equal(float64(numberOfAddrs)))

		metric, err = gauge.ReadMetric()
		Expect(err).NotTo(HaveOccurred())
		Expect(metric.Name).To(Equal("aws.elb.healthy_node_count"))
		Expect(metric.Value).To(Equal(float64(0)))

		Expect(log).To(gbytes.Say(`"addr":\s*"\d+\.\d+.\d+\.\d+`))
	})

	Context("tls.valid_days", func() {

		It("returns >0 for non-expired certificate", func() {
			gauge := TLSValidityGauge(logger, "badssl.com", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(BeNumerically(">", float64(0)))
		})

		It("allows setting port in addr", func() {
			gauge := TLSValidityGauge(logger, "badssl.com:443", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(BeNumerically(">", float64(0)))
		})

		It("tags metrics with only the hostname", func() {
			gauge := TLSValidityGauge(logger, "badssl.com:443", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Tags).To(HaveLen(1))
			Expect(metric.Tags[0]).To(Equal("hostname:badssl.com"))
		})

		It("returns 0 for expired certificate", func() {
			gauge := TLSValidityGauge(logger, "expired.badssl.com", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(Equal(float64(0)))
		})

		It("returns 0 for certificate with incorrect common name", func() {
			gauge := TLSValidityGauge(logger, "wrong.host.badssl.com", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(Equal(float64(0)))
		})

		It("returns 0 for certificate with untrusted root CA", func() {
			gauge := TLSValidityGauge(logger, "untrusted-root.badssl.com", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(Equal(float64(0)))
		})

		It("returns 0 for certificate with self-signed CA", func() {
			gauge := TLSValidityGauge(logger, "self-signed.badssl.com", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(Equal(float64(0)))
		})

		It("returns 0 for certificate with null cipher suite", func() {
			gauge := TLSValidityGauge(logger, "null.badssl.com", 1*time.Second)
			metric, err := gauge.ReadMetric()
			Expect(err).NotTo(HaveOccurred())
			Expect(metric.Name).To(Equal("tls.certificates.validity"))
			Expect(metric.Value).To(Equal(float64(0)))
		})

		It("returns err when cannot connect", func() {
			gauge := TLSValidityGauge(logger, "no.connection.invalid", 1*time.Second)
			_, err := gauge.ReadMetric()
			Expect(err).To(HaveOccurred())
		})

		It("returns err when addr is a URL", func() {
			gauge := TLSValidityGauge(logger, "http://badssl.com", 1*time.Second)
			_, err := gauge.ReadMetric()
			Expect(err).To(HaveOccurred())
		})
	})
})
