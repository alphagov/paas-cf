package acceptance_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	"encoding/json"
)

var _ = Describe("X-Forwarded headers", func() {
	var headers struct {
		X_Forwarded_Proto []string `json:"X-Forwarded-Proto"`
	}

	var _ = BeforeEach(func() {
		appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"-p", "../example-apps/http_tester",
			"-f", "../example-apps/http_tester/manifest.yml",
			"-d", testConfig.GetAppsDomain(),
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

		curlArgs := []string{"-f", "-H", "X-Forwarded-Proto: IPoAC"}
		jsonData := helpers.CurlApp(testConfig, appName, "/print-headers", curlArgs...)

		err := json.Unmarshal([]byte(jsonData), &headers)
		Expect(err).NotTo(HaveOccurred())
	})

	It("should indicate that the user connection was encrypted", func() {
		Expect(headers.X_Forwarded_Proto).Should(HaveLen(1))
		Expect(headers.X_Forwarded_Proto[0]).To(Equal("https"))
	})

})
