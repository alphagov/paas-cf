package acceptance_test

import (
	"bufio"
	"bytes"
	"net/textproto"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
)

var _ = Describe("Strict-Transport-Security headers", func() {

	It("should serve HSTS headers from the apex domain", func() {
		headers := curlApexDomainUrl()
		Expect(headers["Strict-Transport-Security"]).Should(HaveLen(1))
		Expect(headers["Strict-Transport-Security"][0]).To(Equal("max-age=31536000; includeSubDomains; preload"))
	})

	It("should add the header if it is not present", func() {

		appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"-b", testConfig.GetStaticFileBuildpackName(),
			"-p", "../example-apps/static-app",
			"-d", testConfig.GetAppsDomain(),
			"-i", "1",
			"-m", "64M",
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

		headers := curlAppHeaders(appName, "/")

		Expect(headers["Strict-Transport-Security"]).Should(HaveLen(1))
		Expect(headers["Strict-Transport-Security"][0]).To(Equal("max-age=31536000; includeSubDomains; preload"))
	})

	It("should not override the header if set by an app", func() {

		appName := generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
		Expect(cf.Cf(
			"push", appName,
			"-b", "php_buildpack",
			"-p", "../example-apps/strict-transport-security-app",
			"-d", testConfig.GetAppsDomain(),
			"-i", "1",
			"-m", "128M",
		).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))

		headers := curlAppHeaders(appName, "/")

		Expect(headers["Strict-Transport-Security"]).Should(HaveLen(1))
		Expect(headers["Strict-Transport-Security"][0]).To(Equal("max-age=24"))

	})

})

func curlAppHeaders(appName, path string, args ...string) textproto.MIMEHeader {
	curlResponse := helpers.CurlApp(testConfig, appName, path, append(args, "-I")...)

	reader := textproto.NewReader(bufio.NewReader(bytes.NewBufferString(curlResponse)))
	reader.ReadLine()

	m, err := reader.ReadMIMEHeader()
	Expect(err).ShouldNot(HaveOccurred())

	return m
}

func curlApexDomainUrl() textproto.MIMEHeader {
	appsDomain := testConfig.GetAppsDomain()
	apexDomainUrl := testConfig.Protocol() + appsDomain + "/"
	curlCmd := helpers.Curl(testConfig, apexDomainUrl, "-I").Wait(testConfig.DefaultTimeoutDuration())
	Expect(curlCmd).To(Exit(0))
	Expect(string(curlCmd.Err.Contents())).To(HaveLen(0))
	curlResponse := string(curlCmd.Out.Contents())

	reader := textproto.NewReader(bufio.NewReader(bytes.NewBufferString(curlResponse)))
	reader.ReadLine()

	m, err := reader.ReadMIMEHeader()
	Expect(err).ShouldNot(HaveOccurred())

	return m
}
