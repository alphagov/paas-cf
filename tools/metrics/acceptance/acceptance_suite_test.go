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
	metricsLog = log.New(GinkgoWriter, "", log.LstdFlags)
	metricsURL = os.Getenv("PAAS_METRICS_URL")
)

func getMetrics() (map[string]*dto.MetricFamily, error) {
	var (
		err            error
		metricFamilies map[string]*dto.MetricFamily
	)

	timeBetweenAttempts := 1 * time.Second
	maxAttempts := 5
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		if attempt > 1 {
			time.Sleep(timeBetweenAttempts)
		}

		var resp *http.Response
		resp, err = http.Get(metricsURL)
		if err != nil {
			metricsLog.Printf("Received error: %s", err)
			time.Sleep(timeBetweenAttempts)
			continue
		}
		metricsLog.Printf("Got HTTP %d from %s", resp.StatusCode, metricsURL)

		if resp.StatusCode != 200 {
			err = fmt.Errorf(
				"Non-200 HTTP status code from paas-metrics: %d",
				resp.StatusCode,
			)
			metricsLog.Printf("%s", err)
			time.Sleep(timeBetweenAttempts)
			continue
		}

		metricsLog.Printf("Parsing metrics")
		parser := expfmt.TextParser{}
		metricFamilies, err = parser.TextToMetricFamilies(resp.Body)
		if err != nil {
			metricsLog.Printf("Received error: %s", err)
			time.Sleep(timeBetweenAttempts)
			continue
		}
		return metricFamilies, nil
	}

	return metricFamilies, err
}

var _ = BeforeSuite(func() {
	SetDefaultEventuallyTimeout(2 * time.Minute)          // Fail after 1m
	SetDefaultEventuallyPollingInterval(10 * time.Second) // Try every 10s

	SetDefaultConsistentlyDuration(10 * time.Second)       // Test for 10s
	SetDefaultConsistentlyPollingInterval(1 * time.Second) // Try every 1s

	Expect(metricsURL).ToNot(Equal(""), "PAAS_METRICS_URL was empty")

	Eventually(getMetrics).ShouldNot(
		BeEmpty(), "It returns metrics",
	)
	Consistently(getMetrics).ShouldNot(
		BeEmpty(), "It consistently returns metrics",
	)

	Eventually(getMetrics).Should(WithTransform(
		func(fams map[string]*dto.MetricFamily) int {
			return len(fams)
		},
		BeNumerically(">=", numExpectedMetricFamilies),
	),
		fmt.Sprintf(
			"It should return >= %d valid prometheus metrics",
			numExpectedMetricFamilies,
		),
	)
})
