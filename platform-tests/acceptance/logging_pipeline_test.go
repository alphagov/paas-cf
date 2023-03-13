package acceptance_test

import (
	"encoding/json"
	"fmt"
	"os"

	logit "github.com/alphagov/paas-cf/common-go/basic_logit_client"

	"github.com/cloudfoundry/cf-test-helpers/cf"
	"github.com/cloudfoundry/cf-test-helpers/generator"
	"github.com/cloudfoundry/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	gbytes "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"

	"code.cloudfoundry.org/lager"
)

const (
	useLogCache = true
)

var _ = Describe("Logging pipeline", func() {
	var (
		appName string
		startApp = true
	)

	waitForAppServing := func() {
		Eventually(func() string {
			return helpers.CurlApp(testConfig, appName, "/")
		}, "15s", "5s").Should(ContainSubstring("Current time:"))
	}

	JustBeforeEach(func() {
		appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP-LOGGING")
		pushCmd := []string{
			"push", appName,
			"-b", testConfig.GetGoBuildpackName(),
			"-p", "../example-apps/logging-pipeline",
			"-f", "../example-apps/logging-pipeline/manifest.yml",
			"-i", "1",
			"-m", "64M",
		}
		if !startApp {
			pushCmd = append(pushCmd, "--no-start")
		}
		Expect(cf.Cf(pushCmd...).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
		if startApp {
			waitForAppServing()
		}
	})

	JustAfterEach(func() {
		Expect(cf.Cf("delete", appName, "-f", "-r").Wait("15s")).To(Exit(0))
	})

	Context("Application logs (diego)", func() {
		It("logs web process logs", func() {
			Eventually(func() *Session {
				appLogs := cf.Cf("logs", "--recent", appName)
				Expect(appLogs.Wait("30s")).To(Exit(0))
				return appLogs
			}, "2m", "10s").Should(gbytes.Say("APP[/]PROC[/]WEB[/]"))
		})
	})

	Context("Router logs (gorouter)", func() {
		It("logs routed requests", func() {
			Eventually(func() *Session {
				appLogs := cf.Cf("logs", "--recent", appName)
				Expect(appLogs.Wait("30s")).To(Exit(0))
				return appLogs
			}, "2m", "10s").Should(gbytes.Say("RTR[/]"))
		})
	})

	When("A log drain to logit is set up", func() {
		type M map[string]any
		type Response struct {
			Hits struct {
				Total struct {
					Value int `json:"value"`
				} `json:"total"`
			} `json:"hits"`
		}
		var (
			logitClient *logit.Client
		)

		BeforeEach(func() {
			startApp = false

			logger := lager.NewLogger("CATS")
			logger.RegisterSink(lager.NewWriterSink(GinkgoWriter, lager.DEBUG))
			var err error
			logitClient, err = logit.NewService(
				logger,
				os.Getenv("LOGIT_DUMMY_TENANT_CONFIG_OPENSEARCH_URL"),
				os.Getenv("LOGIT_DUMMY_TENANT_CONFIG_OPENSEARCH_API_KEY"),
			)
			Expect(err).ToNot(HaveOccurred())
		})

		JustBeforeEach(func() {
			endpoint := os.Getenv("LOGIT_DUMMY_TENANT_CONFIG_ENDPOINT")
			port := os.Getenv("LOGIT_DUMMY_TENANT_CONFIG_TCP_SSL_PORT")
			Expect(endpoint).ToNot(BeEmpty())
			Expect(port).ToNot(BeEmpty())
			Expect(cf.Cf(
				"create-user-provided-service", "logit-ssl-drain",
				"-l", fmt.Sprintf(
					"syslog-tls://%s:%s",
					endpoint,
					port,
				),
			).Wait("20s")).To(Exit(0))
			Expect(cf.Cf(
				"bind-service", appName, "logit-ssl-drain",
			).Wait("20s")).To(Exit(0))
			Expect(
				cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration()),
			).To(Exit(0))
			waitForAppServing()
		})

		AfterEach(func() {
			Expect(cf.Cf(
				"delete-service", "-f", "logit-ssl-drain",
			).Wait("20s")).To(Exit(0))
		})

		logitHasSourceType := func(sourceType string) bool {
			query, err := json.Marshal(M{
				"query": M{"bool": M{
					"must": []any{
						M{"match_phrase": M{"cf.app": appName}},
						M{"match_phrase": M{"cf_tags.source_type": sourceType}},
					},
					"filter": []any{
						M{"range": M{
							"@timestamp": M{"time_zone": "UTC", "gt": "now-1h"},
						}},
					},
				}},
				"size": 0,
				"track_total_hits": true,
			})
			Expect(err).ToNot(HaveOccurred())

			response := Response{}
			err = logitClient.Search(string(query), &response)
			Expect(err).ToNot(HaveOccurred())
			return response.Hits.Total.Value > 0
		}

		// ginkgo refuses to allow units to share a common setup phase while still
		// running the units in parallel, so to avoid checks for each log type
		// having to spin up an app of their own but still not having to wait for
		// each timeout serially in the case where all fail, we've got to jam them
		// all into the same unit :(
		It("receives all expected types of log message", func() {
			sourceTypes := []string{"RTR", "CELL", "API", "APP/PROC/WEB", "STG"}
			allPresent := map[string]bool{}
			for _, sourceType := range sourceTypes {
				allPresent[sourceType] = true
			}

			i := 0
			Eventually(func() map[string]bool {
				// give it something to log about
				helpers.CurlApp(testConfig, appName, "/")
				if i == 0 {
					// really give it something to log about
					cf.Cf("restage", appName)  // ignore result
				}
				i = (i+1) % 4

				ret := map[string]bool{}
				for _, sourceType := range sourceTypes {
					ret[sourceType] = logitHasSourceType(sourceType)
				}
				return ret
			}, "15m", "30s").Should(Equal(allPresent))
		})
	})
})
