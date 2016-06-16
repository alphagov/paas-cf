package availability_test

import (
	"fmt"
	"time"

	"github.com/alphagov/paas-cf/tests/helpers"

	vegeta "github.com/tsenart/vegeta/lib"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (
	availabilityTestRate             = 10
	availabilityTestMaxDuration      = 2 * time.Hour
	availabilityTestMaxLatency       = 300 * time.Millisecond
	availabilityTestMaxErrors        = 0
	availabilitySuccessRateThreshold = 99.9
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

func deploymentHasFinishedDummy() {
	return false
}

func errorRateThreshold(metrics vegeta.Metrics, minimumTestDuration time.Duration, maximumErrorRate float64) bool {
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
	var stopAttackCriteria func() bool

	Context("when runs (until the deployment is finished or error rate > 50%)", func() {
		var attacker *vegeta.Attacker
		var resultChannel <-chan *vegeta.Result

		BeforeEach(func() {
			stopAttackCriteria = func() bool {
				if deploymentHasFinishedDummy() {
					return true
				}
				if errorRateThreshold(metrics, minimumTestDuration, maximumErrorRate) {
					return true
				}
				return false
			}
		})

		It(fmt.Sprintf("does not get reuest success rate less than %.2f%%", availabilitySuccessRateThreshold), func() {
			appUri := "https://healthcheck." + helpers.GetAppsDomainZoneName() + "/?availability-test=" + helpers.GetResourceVersion()

			go func() {
				defer metrics.Close()
				for res := range resultChannel {
					metrics.Add(res)
				}
			}()

			attacker, resultChannel = loadTest(appUri, "/", availabilityTestRate)
			defer attacker.Stop()

			Eventually(
				stopAttackCriteria,
				availabilityTestMaxDuration,
				5*time.Second,
			).Should(BeTrue(), "Deployment did not finish in the expected time")

			attacker.Stop()
			metrics.Close()

			Expect(metrics.Success*100).To(
				BeNumerically(">=", availabilitySuccessRateThreshold),
				"Errors detected during the attack: %v", metrics.Errors,
			)
		})
	})

})
