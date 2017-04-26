package acceptance_test

import (
	"fmt"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

var _ = Describe("Apps response size", func() {
	var appName string

	BeforeEach(func() {
		appName = generator.PrefixedRandomName("CATS-APP-DORA-")
		Expect(cf.Cf(
			"push", appName,
			"-b", config.RubyBuildpackName,
			"-p", "../../../../cf-release/src/github.com/cloudfoundry/cf-acceptance-tests/assets/dora",
			"-d", config.AppsDomain,
			"-i", "1",
			"-m", "256M",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))
	})

	It("should serve request and response bodies of increasing sizes", func() {
		for responsekB := 1; responsekB <= 200; responsekB += 10 {
			By(fmt.Sprintf("response size of %d kB", responsekB))
			response := helpers.CurlAppWithTimeout(
				appName,
				fmt.Sprintf("/largetext/%d", responsekB),
				5*time.Second,
			)
			Expect(response).To(HaveLen(responsekB * int(KILOBYTE)))
		}
	})
})
