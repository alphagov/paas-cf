package acceptance_test

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

const (
	letters  = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	utfchars = "スタック・オーバーフロー はプログラマ"
)

var _ = Describe("HTTP edge cases", func() {
	Describe("Using dora", func() {
		var appName string

		BeforeEach(func() {
			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP-DORA")
			Expect(cf.Cf(
				"push", appName,
				"-b", testConfig.GetRubyBuildpackName(),
				"-p", "../../../../../cf-acceptance-tests/assets/dora",
				"-d", testConfig.GetAppsDomain(),
				"-i", "1",
				"-m", "256M",
			).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		})

		It("should serve response bodies of increasing sizes", func() {
			for responsekB := 1; responsekB <= 200; responsekB += 10 {
				By(fmt.Sprintf("response size of %d kB", responsekB))
				response := helpers.CurlAppWithTimeout(
					testConfig,
					appName,
					fmt.Sprintf("/largetext/%d", responsekB),
					5*time.Second,
				)
				Expect(response).To(HaveLen(responsekB * int(KILOBYTE)))
			}
		})
	})

	Describe("Using http_tester", func() {
		var appName string

		BeforeEach(func() {
			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP-HTTP-TESTER")
			Expect(cf.Cf(
				"push", appName,
				"-p", "../../../example-apps/http_tester",
				"-f", "../../../example-apps/http_tester/manifest.yml",
				"-d", testConfig.GetAppsDomain(),
			).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		})

		It("should accept large request body sizes", func() {
			for requestkB := 1; requestkB <= 200; requestkB += 10 {
				By(fmt.Sprintf("request size of %d kB", requestkB))
				buffer := new(bytes.Buffer)
				file, err := os.Open("/dev/zero")
				Expect(err).NotTo(HaveOccurred())
				defer file.Close()

				copied, err := io.CopyN(buffer, file, int64(requestkB*int(KILOBYTE)))
				Expect(err).NotTo(HaveOccurred())
				fmt.Fprintf(GinkgoWriter, "Successfully copied %d bytes\n", copied)

				appUri := helpers.AppUri(appName, "/body-size", testConfig)

				req, err := http.NewRequest("POST", appUri, buffer)
				Expect(err).NotTo(HaveOccurred())

				response, err := httpClient.Do(req)
				Expect(err).NotTo(HaveOccurred())
				returnedBody, err := ioutil.ReadAll(response.Body)
				Expect(err).NotTo(HaveOccurred())
				returnedBodySize, err := strconv.Atoi(string(returnedBody))
				Expect(err).NotTo(HaveOccurred())
				Expect(returnedBodySize).Should(Equal(requestkB * int(KILOBYTE)))
			}
		})

		It("should accept large request header sizes", func() {
			for headerkB := 1; headerkB <= 7; headerkB += 1 {
				By(fmt.Sprintf("request header size of %d kB", headerkB))

				curlArgs := []string{"-H", fmt.Sprintf("test-header: %s", randStringBytes(headerkB*int(KILOBYTE)))}
				response := helpers.CurlApp(testConfig, appName, "/header-size", curlArgs...)

				Expect(response).To(BeEquivalentTo(strconv.Itoa(headerkB * int(KILOBYTE))))
			}
		})

		It("should accept large response header sizes", func() {
			for headerkB := 1; headerkB <= 7; headerkB += 1 {
				By(fmt.Sprintf("response header size of %d kB", headerkB))

				appUri := helpers.AppUri(appName, fmt.Sprintf("/big-header?size=%d", headerkB), testConfig)

				response, err := httpClient.Get(appUri)
				Expect(err).NotTo(HaveOccurred())
				testHeader := response.Header.Get("test-header")
				Expect(len(testHeader)).To(Equal(headerkB * int(KILOBYTE)))
			}
		})

		It("allow egress connectivity", func() {
			response := helpers.CurlApp(testConfig, appName, "/egress?domain=www.gov.uk")

			Expect(response).To(BeEquivalentTo("OK"))
		})

		It("can connect to other app in the paas", func() {
			appName2 := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP-HTTP-TESTER")
			Expect(cf.Cf(
				"push", appName2,
				"-p", "../../../example-apps/http_tester",
				"-f", "../../../example-apps/http_tester/manifest.yml",
				"-d", testConfig.GetAppsDomain(),
			).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			curlArgs := []string{"-k"}
			response := helpers.CurlApp(testConfig, appName, fmt.Sprintf("/egress?domain=%s.%s", appName2, testConfig.GetAppsDomain()), curlArgs...)

			Expect(response).To(BeEquivalentTo("OK"))
		})

		It("should accept slow responses", func() {
			requesttext := "slow response"
			requestURL, err := url.Parse("/slow-response")
			Expect(err).ToNot(HaveOccurred())
			parameters := url.Values{}
			parameters.Add("text", requesttext)
			requestURL.RawQuery = parameters.Encode()
			response := helpers.CurlApp(testConfig, appName, requestURL.RequestURI())
			Expect(response).To(Equal(requesttext))
		})

		It("should accept a long query string", func() {
			paramLength := 8
			queryLength := 4096
			numberOfParams := (queryLength / paramLength)
			requestURL, err := url.Parse("/long-url")
			Expect(err).ToNot(HaveOccurred())
			parameters := url.Values{}
			for i := 1; i <= numberOfParams; i++ {
				keyName := "p" + strconv.Itoa(i)
				valueLength := paramLength - len("&"+keyName+"=")
				parameters.Add(keyName, randStringBytes(valueLength))
			}
			requestURL.RawQuery = parameters.Encode()
			response := helpers.CurlApp(testConfig, appName, requestURL.RequestURI())
			Expect(response).To(BeEquivalentTo(requestURL.RawQuery))
			Expect(response).To(HaveLen(queryLength - len("?")))
		})

		It("should accept utf query string", func() {
			requestURL, err := url.Parse("/long-url")
			Expect(err).ToNot(HaveOccurred())
			parameters := url.Values{}
			parameters.Add("q", utfchars)
			requestURL.RawQuery = parameters.Encode()
			response := helpers.CurlApp(testConfig, appName, requestURL.RequestURI())
			parsedQuery, err := url.ParseQuery(response)
			Expect(err).ToNot(HaveOccurred())
			Expect(parsedQuery["q"][0]).To(BeEquivalentTo(utfchars))
		})
	})
})

func randStringBytes(n int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}
