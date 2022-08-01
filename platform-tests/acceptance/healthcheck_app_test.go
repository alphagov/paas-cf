package acceptance_test

import (
	"bytes"
	"compress/gzip"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	"github.com/cloudfoundry/cf-test-helpers/helpers"
)

var _ = Describe("healthcheck app deployed by pipeline", func() {
	const appName = "healthcheck"
	var response string

	BeforeEach(func() {
		response = helpers.CurlApp(testConfig, appName, "/", "-f")
	})

	Describe("/ endpoint", func() {
		It("has a response size larger than 200kB", func() {
			Expect(len(response)).To(BeNumerically(">", 200*KILOBYTE))
		})

		It("has a gzipped response size larger than 50kB", func() {
			var buf bytes.Buffer
			gzipWriter := gzip.NewWriter(&buf)
			_, err := gzipWriter.Write([]byte(response))
			Expect(err).ToNot(HaveOccurred())
			Expect(gzipWriter.Close()).To(Succeed())

			Expect(buf.Len()).To(BeNumerically(">", 50*KILOBYTE))
		})

		It("has response string used by Pingdom check", func() {
			Expect(response).To(ContainSubstring("END OF THIS PROJECT GUTENBERG EBOOK"))
		})
	})
})
