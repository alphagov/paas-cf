package acceptance

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"testing"
	"time"

	dto "github.com/prometheus/client_model/go"
	"github.com/prometheus/common/expfmt"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (
	// We usually serve 26 metrics, but we expect 18 or more
	// 6 optional metrics are aws.cloudfront.* which are traffic dependent
	// 2 optional metrics are cdn.tls.* which depend on a cdn routed app
	numExpectedMetricFamilies = 18
)

func TestAcceptanceTests(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Acceptance Suite")
}

var (
	metricsURL     = os.Getenv("PAAS_METRICS_URL")
	metricFamilies map[string]*dto.MetricFamily
)

var _ = BeforeSuite(func() {
	log.Printf("Running BeforeSuite")

	SetDefaultEventuallyTimeout(2 * time.Minute)          // Fail after 1m
	SetDefaultEventuallyPollingInterval(10 * time.Second) // Try every 10s

	SetDefaultConsistentlyDuration(10 * time.Second)       // Test for 10s
	SetDefaultConsistentlyPollingInterval(1 * time.Second) // Try every 1s

	Expect(metricsURL).ToNot(Equal(""), "PAAS_METRICS_URL was empty")

	getRawMetrics := func() (int, error) {
		log.Printf("Attempting to get metrics from %s", metricsURL)

		resp, err := http.Get(metricsURL)
		if err != nil {
			log.Printf("Received error: %s", err)
			return 0, err
		}

		log.Printf("Got HTTP %d from %s", resp.StatusCode, metricsURL)
		return resp.StatusCode, nil
	}

	Eventually(getRawMetrics).Should(
		BeNumerically("==", 200),
		"It should eventually return a response",
	)

	Consistently(getRawMetrics).Should(
		BeNumerically("==", 200),
		"It should consistently return a response",
	)

	Eventually(func() (int, error) {
		log.Printf("Getting metrics for parsing from %s", metricsURL)

		resp, err := http.Get(metricsURL)
		if err != nil {
			log.Printf("Received error: %s", err)
			return 0, err
		}

		log.Printf("Parsing metrics")
		parser := expfmt.TextParser{}
		metricFamilies, err = parser.TextToMetricFamilies(resp.Body)
		if err != nil {
			log.Printf("Received error: %s", err)
			return 0, err
		}

		log.Printf("Parsed %d metric families", len(metricFamilies))
		return len(metricFamilies), nil
	}).Should(
		BeNumerically(">=", numExpectedMetricFamilies),
		fmt.Sprintf(
			"It should return >= %d valid prometheus metrics",
			numExpectedMetricFamilies,
		),
	)
})
