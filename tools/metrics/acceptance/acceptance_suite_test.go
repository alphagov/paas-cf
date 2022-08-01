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

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

const (
	// We usually serve 27 metrics, but we expect 19 or more
	// 6 optional metrics are aws.cloudfront.* which are traffic dependent
	// 2 optional metrics are cdn.tls.* which depend on a cdn routed app
	numExpectedMetricFamilies = 19
)

func TestAcceptanceTests(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Acceptance Suite")
}

var (
	metricsLog = log.New(GinkgoWriter, "", log.LstdFlags)
	metricsURL = os.Getenv("PAAS_METRICS_URL")
)

func getMetricNames() ([]string, error) {
	var (
		err            error
		metricFamilies map[string]*dto.MetricFamily

		metricFamilyNames = []string{}
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
		metricsLog.Printf("Parsed metrics")
		for familyName := range metricFamilies {
			metricFamilyNames = append(metricFamilyNames, familyName)
		}
		return metricFamilyNames, nil
	}

	return metricFamilyNames, err
}

var _ = BeforeSuite(func() {
	SetDefaultEventuallyTimeout(10 * time.Minute)         // Fail after 10m
	SetDefaultEventuallyPollingInterval(10 * time.Second) // Try every 10s

	SetDefaultConsistentlyDuration(10 * time.Second)       // Test for 10s
	SetDefaultConsistentlyPollingInterval(1 * time.Second) // Try every 1s

	Expect(metricsURL).ToNot(Equal(""), "PAAS_METRICS_URL was empty")

	By("Checking readiness")

	Eventually(getMetricNames).ShouldNot(
		BeEmpty(), "It returns metrics",
	)
	Consistently(getMetricNames).ShouldNot(
		BeEmpty(), "It consistently returns metrics",
	)

	Eventually(getMetricNames).Should(WithTransform(
		func(fams []string) int {
			return len(fams)
		},
		BeNumerically(">=", numExpectedMetricFamilies),
	),
		fmt.Sprintf(
			"It should return >= %d valid prometheus metrics",
			numExpectedMetricFamilies,
		),
	)

	By("Ready")
})
