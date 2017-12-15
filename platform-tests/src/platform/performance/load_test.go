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
	loadTestLatency  = 50 * time.Millisecond
)

func loadTest(appName string, rate uint64, duration time.Duration, keepalive bool) (m *vegeta.Metrics) {
	appUri := helpers.AppUri(appName, "/", testConfig)
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
	return &metrics
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
		appName = generator.PrefixedRandomName(testConfig.NamePrefix, "APP")

		Expect(cf.Cf("push", appName,
			"--no-start",
			"-b", testConfig.StaticFileBuildpackName,
			"-m", DEFAULT_MEMORY_LIMIT,
			"-p", "../../../example-apps/static-app/",
			"-d", testConfig.AppsDomain,
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

		Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
	})

	AfterEach(func() {
		Expect(cf.Cf("delete", appName, "-f", "-r").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
	})

	Context("without HTTP Keep-Alive", func() {
		It("has a response latency within our threshold", func() {
			metrics := loadTest(appName, loadTestRate, loadTestDuration, false)
			generateJsonReport(metrics, "load-test-no-keep-alive.json")
			vegeta.NewTextReporter(metrics).Report(os.Stdout)
			Expect(metrics.Latencies.P95).To(BeNumerically("<", loadTestLatency))
		})
	})

	Context("with HTTP Keep-Alive", func() {
		It("has a response latency within our threshold", func() {
			metrics := loadTest(appName, loadTestRate, loadTestDuration, true)
			generateJsonReport(metrics, "load-test-keep-alive.json")
			vegeta.NewTextReporter(metrics).Report(os.Stdout)
			Expect(metrics.Latencies.P95).To(BeNumerically("<", loadTestLatency))
		})
	})
})
