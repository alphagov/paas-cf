package config_test

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"time"

	cfg "github.com/cloudfoundry-incubator/cf-test-helpers/config"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type RequiredConfig struct {
	ApiEndpoint       string `json:"api"`
	AdminUser         string `json:"admin_user"`
	AdminPassword     string `json:"admin_password"`
	SkipSSLValidation bool   `json:"skip_ssl_validation"`
	AppsDomain        string `json:"apps_domain"`
	UseHttp           bool   `json:"use_http"`
}

var config *cfg.Config
var tmpFile *os.File
var err error
var _ = Describe("Config", func() {
	BeforeEach(func() {
		requiredConfig := RequiredConfig{
			ApiEndpoint:       "somewhere.over.the.rainbow",
			AdminUser:         "admin",
			AdminPassword:     "admin",
			SkipSSLValidation: true,
			AppsDomain:        "cf-app.over.the.rainbow",
			UseHttp:           true,
		}

		tmpFile, err = ioutil.TempFile("", "cf-test-helpers-config")
		Expect(err).NotTo(HaveOccurred())

		encoder := json.NewEncoder(tmpFile)
		err = encoder.Encode(requiredConfig)
		Expect(err).NotTo(HaveOccurred())

		err = tmpFile.Close()
		Expect(err).NotTo(HaveOccurred())

		os.Setenv("CONFIG", tmpFile.Name())
		config = cfg.LoadConfig()
	})

	AfterEach(func() {
		err := os.Remove(tmpFile.Name())
		Expect(err).NotTo(HaveOccurred())
	})

	It("should have the right defaults", func() {
		Expect(config.IncludeApps).To(BeTrue())
		Expect(config.UseExistingOrganization).To(BeFalse())
		Expect(config.UseExistingSpace).To(BeFalse())
		Expect(config.ExistingOrganization).To(BeEmpty())
		Expect(config.DefaultTimeout).To(Equal(30))
		Expect(config.DefaultTimeoutDuration()).To(Equal(30 * time.Second))
		Expect(config.CfPushTimeout).To(Equal(2))
		Expect(config.CfPushTimeoutDuration()).To(Equal(2 * time.Minute))
		Expect(config.LongCurlTimeout).To(Equal(2))
		Expect(config.LongCurlTimeoutDuration()).To(Equal(2 * time.Minute))
		Expect(config.BrokerStartTimeout).To(Equal(5))
		Expect(config.BrokerStartTimeoutDuration()).To(Equal(5 * time.Minute))
		Expect(config.AsyncServiceOperationTimeout).To(Equal(2))
		Expect(config.AsyncServiceOperationTimeoutDuration()).To(Equal(2 * time.Minute))

		// undocumented
		Expect(config.DetectTimeout).To(Equal(5))
		Expect(config.DetectTimeoutDuration()).To(Equal(5 * time.Minute))
		Expect(config.SleepTimeout).To(Equal(30))
		Expect(config.SleepTimeoutDuration()).To(Equal(30 * time.Second))
	})

	It("should have duration timeouts based on the configured values", func() {
		cfg := cfg.Config{
			DefaultTimeout:               12,
			CfPushTimeout:                34,
			LongCurlTimeout:              56,
			BrokerStartTimeout:           78,
			AsyncServiceOperationTimeout: 90,
			DetectTimeout:                100,
			SleepTimeout:                 101,
		}

		Expect(cfg.DefaultTimeoutDuration()).To(Equal(12 * time.Second))
		Expect(cfg.CfPushTimeoutDuration()).To(Equal(34 * time.Minute))
		Expect(cfg.LongCurlTimeoutDuration()).To(Equal(56 * time.Minute))
		Expect(cfg.BrokerStartTimeoutDuration()).To(Equal(78 * time.Minute))
		Expect(cfg.AsyncServiceOperationTimeoutDuration()).To(Equal(90 * time.Minute))
		Expect(cfg.DetectTimeoutDuration()).To(Equal(100 * time.Minute))
		Expect(cfg.SleepTimeoutDuration()).To(Equal(101 * time.Second))
	})

	It("should have a function to get the AppsDomain", func() {
		cfg := cfg.Config{
			AppsDomain: "abc.com",
		}
		Expect(cfg.GetAppsDomain()).To(Equal("abc.com"))
	})
})
