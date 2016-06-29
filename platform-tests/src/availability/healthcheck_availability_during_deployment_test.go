package availability_test

import (
	"fmt"
	"sync"
	"time"

	"availability/helpers"

	vegeta "github.com/tsenart/vegeta/lib"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (
	availabilityTestRate             = 10
	availabilityTestMaxDuration      = 2 * time.Hour
	availabilityTestMaxLatency       = 300 * time.Millisecond
	availabilityTestMaxErrors        = 0
	availabilitySuccessRateThreshold = 100.0
	minimumTestDuration              = 15 * time.Second
	maximumErrorRate                 = 0.5

	vegetaRunForever = 0 * time.Second
	vegetaKeepAlive  = true
)

func loadTest(appUri string, endpoint string, rate uint64) (*vegeta.Attacker, <-chan *vegeta.Result) {
	targeter := vegeta.NewStaticTargeter(vegeta.Target{
		Method: "GET",
		URL:    appUri,
	})

	attacker := vegeta.NewAttacker(vegeta.KeepAlive(vegetaKeepAlive))
	res := attacker.Attack(targeter, rate, vegetaRunForever)

	return attacker, res
}

func errorRateThreshold(metrics *vegeta.Metrics, minimumTestDuration time.Duration, maximumErrorRate float64) bool {
	// metrics.Close() does trigger the computation of metrics, but does not stop any process
	metrics.Close()

	fmt.Printf(
		" - Duration: %s, Requests: %d, Non 200 Requests: %d, Success Rate: %.2f%%\n",
		metrics.Duration,
		metrics.Requests,
		metrics.Requests-uint64(metrics.StatusCodes["200"]),
		metrics.Success*100,
	)

	if metrics.Duration > minimumTestDuration {
		if metrics.Success < (1 - maximumErrorRate) {
			return true
		}
	}
	return false
}

var _ = Describe("Availability test", func() {

	var metrics vegeta.Metrics
	var metricsLock sync.Mutex
	var stopAttackCriteria func() bool

	Context("when runs (until the deployment is finished or error rate > 50%)", func() {
		var attacker *vegeta.Attacker
		var resultChannel <-chan *vegeta.Result

		BeforeEach(func() {
			stopAttackCriteria = func() bool {
				if helpers.DeploymentHasFinishedInConcourse() {
					return true
				}
				metricsLock.Lock()
				defer metricsLock.Unlock()
				if errorRateThreshold(&metrics, minimumTestDuration, maximumErrorRate) {
					return true
				}
				return false
			}
		})

		It(fmt.Sprintf("does not get request success rate less than %.2f%%", availabilitySuccessRateThreshold), func() {
			appUri := "https://healthcheck." + helpers.GetAppsDomainZoneName() + "/?availability-test=" + helpers.GetResourceVersion()

			attacker, resultChannel = loadTest(appUri, "/", availabilityTestRate)
			defer attacker.Stop()

			var wg sync.WaitGroup
			wg.Add(1)
			go func() {
				defer wg.Done()
				for res := range resultChannel {
					metricsLock.Lock()
					metrics.Add(res)
					metricsLock.Unlock()
				}
			}()

			Eventually(
				stopAttackCriteria,
				availabilityTestMaxDuration,
				5*time.Second,
			).Should(BeTrue(), "Deployment did not finish in the expected time")

			attacker.Stop()
			wg.Wait() // Ensure all results have been collected.

			metrics.Close()
			Expect(metrics.Success*100).To(
				BeNumerically(">=", availabilitySuccessRateThreshold),
				"Errors detected during the attack: %v", metrics.Errors,
			)
		})
	})

})
