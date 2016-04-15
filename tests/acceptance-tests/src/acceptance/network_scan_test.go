package acceptance_test

import (
	"os"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	"encoding/json"
)

type Result struct {
	Host        string `json:"host"`
	OpenedPorts []int  `json:"openedports"`
}

type Results struct {
	Results []Result `json:"results"`
}

type Trigger struct {
	Trigger bool `json:"trigger"`
}

var _ = Describe("Network scan", func() {
	var (
		appName      string
		results      Results
		SCAN_TIMEOUT = 30 * time.Minute
	)

	var _ = BeforeEach(func() {
		appName = generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"--no-start",
			"-b", "https://github.com/cloudfoundry/go-buildpack.git#v1.7.3",
			"-p", "../../apps/network_scan/",
			"-d", config.AppsDomain,
			"-c", "./bin/network_scan",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		iplist := os.Getenv("IP_LIST")
		Expect(cf.Cf("set-env", appName, "IP_LIST", iplist).Wait(DEFAULT_TIMEOUT)).To(Exit(0))
		Expect(cf.Cf("start", appName).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
	})

	It("should not detect opened ports", func() {
		var trigger Trigger
		jsonData := helpers.CurlApp(appName, "/triggerscan")
		err := json.Unmarshal([]byte(jsonData), &trigger)
		Expect(err).NotTo(HaveOccurred())
		Expect(trigger.Trigger).To(Equal(true))
		timestamp := time.Now()
		for {
			Expect(time.Now().Sub(timestamp)).To(BeNumerically("<", SCAN_TIMEOUT))
			jsonData := helpers.CurlAppRoot(appName)
			err := json.Unmarshal([]byte(jsonData), &results)
			Expect(err).NotTo(HaveOccurred())

			if results.Results != nil {
				for host := range results.Results {
					Expect(len(results.Results[host].OpenedPorts)).To(Equal(0))
					return
				}
			}
			time.Sleep(1 * time.Second)
		}
	})

})
