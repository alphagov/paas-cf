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
		appName := generator.PrefixedRandomName("CATS-APP-")
		Expect(cf.Cf(
			"push", appName,
			"-b", config.GoBuildpackName,
			"-p", "../../example-apps/print_request_headers",
			"-d", config.AppsDomain,
			"-c", "./bin/debug_app; sleep 1; echo 'done'",
		).Wait(CF_PUSH_TIMEOUT)).To(Exit(0))

		curlArgs := []string{"-f", "-H", "X-Forwarded-Proto: IPoAC"}
		jsonData := helpers.CurlApp(appName, "/", curlArgs...)

		err := json.Unmarshal([]byte(jsonData), &headers)
		Expect(err).NotTo(HaveOccurred())
	})

	It("should indicate that the user connection was encrypted", func() {
		Expect(headers.X_Forwarded_Proto).Should(HaveLen(1))
		Expect(headers.X_Forwarded_Proto[0]).To(Equal("https"))
	})

})
