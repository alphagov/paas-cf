package performance_test

import (
	"bufio"
	"os"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
	"github.com/tsenart/vegeta/lib"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

const (
	loadTestRate     = 100
	loadTestDuration = 10 * time.Second
	loadTestLatency  = 300 * time.Millisecond
)

func loadTest(appName string, rate uint64, duration time.Duration, keepalive bool) (m *vegeta.Metrics, latency time.Duration) {
	appUri := helpers.AppRootUri(appName)
	targeter := vegeta.NewStaticTargeter(vegeta.Target{
		Method: "GET",
		URL:    appUri,
	})
	var metrics vegeta.Metrics
	defer metrics.Close()

	attacker := vegeta.NewAttacker(vegeta.KeepAlive(keepalive))

	for res := range attacker.Attack(targeter, rate, duration) {
		metrics.Add(res)
	}
	return &metrics, metrics.Latencies.P99
}

func generateJsonReport(m *vegeta.Metrics, filename string) {
	jsonReporter := vegeta.NewJSONReporter(m)
	f, err := os.Create(filename)
	defer f.Close()
	Expect(err).To(Succeed())
	w := bufio.NewWriter(f)
	jsonReporter.Report(w)
	w.Flush()
}

var _ = Describe("Load performance", func() {

	var appName string

	BeforeEach(func() {
		appName = generator.PrefixedRandomName("CATS-APP-")

		Expect(cf.Cf("push", appName,
			"--no-start",
			"-b", config.StaticFileBuildpackName,
			"-m", DEFAULT_MEMORY_LIMIT,
			"-p", "../../example-apps/static-app/",
			"-d", config.AppsDomain,
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
	})

	AfterEach(func() {
		Expect(cf.Cf("delete", appName, "-f", "-r").Wait(DEFAULT_TIMEOUT)).To(Exit(0))
	})
	Context("without HTTP Keep-Alive", func() {
		It("has a response latency within our threshold", func() {
			metrics, latency := loadTest(appName, loadTestRate, loadTestDuration, false)
			generateJsonReport(metrics, "load-test-no-keep-alive.json")
			vegeta.NewTextReporter(metrics).Report(os.Stdout)
			Expect(time.Duration.Nanoseconds(latency)).To(BeNumerically("<", loadTestLatency))

		})
	})
	Context("with HTTP Keep-Alive", func() {
		It("has a response latency within our threshold", func() {
			metrics, latency := loadTest(appName, loadTestRate, loadTestDuration, true)
			generateJsonReport(metrics, "load-test-keep-alive.json")
			vegeta.NewTextReporter(metrics).Report(os.Stdout)
			Expect(time.Duration.Nanoseconds(latency)).To(BeNumerically("<", loadTestLatency))

		})
	})
})
