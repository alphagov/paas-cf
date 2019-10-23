package main_test

import (
	"context"
	"net"
	"net/http"
	"os"
	"time"

	"code.cloudfoundry.org/lager"
	. "github.com/alphagov/paas-cf/tools/metrics"
	"github.com/alphagov/paas-cf/tools/metrics/fakes"
	"github.com/alphagov/paas-cf/tools/metrics/pkg/pingdumb"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
)

var _ = Describe("ELB Gauges", func() {

	var (
		logger    lager.Logger
		log       *gbytes.Buffer
		resolvers []*net.Resolver
		server    *http.Server
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
					logger.Info("attempting-dial", lager.Data{"address": address})
					return dialer.DialContext(ctx, network, "127.0.0.1:8553")
				},
			},
		}

		go func() {
			//defer GinkgoRecover()
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
		logger.RegisterSink(lager.NewWriterSink(os.Stdout, lager.INFO))
		logger.RegisterSink(lager.NewWriterSink(log, lager.INFO))
	})

	It("emits two metrics", func() {
		logger.Info("test-output", lager.Data{"address": "http://gauges.test:8580"})
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

})
