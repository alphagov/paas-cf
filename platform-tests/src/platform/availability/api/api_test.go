package api_availability

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"time"

	"platform/availability/helpers"
	"platform/availability/monitor"

	"github.com/cloudfoundry-community/go-cfclient"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (
	maxConcourseConnectionFailures = 5
	maxWarnings                    = 5
	numWorkers                     = 4
	taskRatePerSecond              = 2
)

func lg(things ...interface{}) {
	fmt.Fprintln(os.Stdout, things...)
}

var warningMatchers = []*regexp.Regexp{
	regexp.MustCompile("cannot fetch token: 503 Service Unavailable"),
	regexp.MustCompile(`CF-StatsUnavailable\|200002`),
}

var _ = Describe("API Availability Monitoring", func() {

	It("should have uninterupted access to cloudfoundry api during deploy", func() {
		cfConfig := &cfclient.Config{
			ApiAddress:        fmt.Sprintf("https://api.%s", helpers.MustGetenv("SYSTEM_DNS_ZONE_NAME")),
			Username:          helpers.MustGetenv("CF_USER"),
			Password:          helpers.MustGetenv("CF_PASS"),
			SkipSslValidation: helpers.MustGetenv("SKIP_SSL_VALIDATION") == "true",
			HttpClient: &http.Client{
				Transport: &http.Transport{
					DisableKeepAlives: true,
				},
			},
		}
		monitor := monitor.NewMonitor(cfConfig, os.Stdout, numWorkers, warningMatchers, taskRatePerSecond)
		deployment := helpers.ConcourseDeployment()

		monitor.Add("Listing all apps in a space", func(cfg *cfclient.Config) error {
			cf, err := cfclient.NewClient(cfg)
			if err != nil {
				return fmt.Errorf("Failed to connect to Cloud Foundry API: %s", err)
			}
			org, err := cf.GetOrgByName("admin")
			if err != nil {
				return fmt.Errorf("Failed to fetch 'admin' org: %s", err)
			}

			space, err := cf.GetSpaceByName("healthchecks", org.Guid)
			if err != nil {
				return fmt.Errorf("Failed to fetch 'healthchecks' space within 'admin' org: %s", err)
			}
			apps, err := cf.ListAppsByQuery(url.Values{"q": []string{
				"organization_guid:" + org.Guid,
				"space_guid:" + space.Guid,
			}})
			if err != nil {
				return fmt.Errorf("Failed to query apps within space 'healthchecks' in org 'admin': %s", err)
			} else if len(apps) < 1 {
				return fmt.Errorf("Failed to find any apps in the 'healthchecks' space, expected at least one to be returned")
			}

			return nil
		})

		monitor.Add("Fetching detailed app information", func(cfg *cfclient.Config) error {
			cf, err := cfclient.NewClient(cfg)
			if err != nil {
				return fmt.Errorf("Failed to connect to Cloud Foundry API: %s", err)
			}
			org, err := cf.GetOrgByName("admin")
			if err != nil {
				return fmt.Errorf("Failed to fetch 'admin' org")
			}

			apps, err := cf.ListAppsByQuery(url.Values{"q": []string{
				"name:" + appName,
				"organization_guid:" + org.Guid,
			}})
			if err != nil {
				return fmt.Errorf("Failed to query app by name within 'admin' org: %s", err)
			} else if len(apps) == 0 {
				return fmt.Errorf("Failed to find the app named '%s' within 'admin' org", appName)
			}
			app := apps[0]

			if _, err := cf.GetAppStats(app.Guid); err != nil {
				return fmt.Errorf("Failed to fetch app stats: %s", err)
			}

			if _, err := cf.GetAppInstances(app.Guid); err != nil {
				return fmt.Errorf("Failed to fetch app instances: %s", err)
			}

			if _, err := cf.GetAppRoutes(app.Guid); err != nil {
				return fmt.Errorf("Failed to fetch app routes: %s", err)
			}

			return nil
		})

		// poll concourse job status til done
		go func(concourseConnectionAttemptsRemaining int64) {
			defer GinkgoRecover()
			for {
				<-time.After(2 * time.Second)
				if done, err := deployment.Complete(); err != nil {
					concourseConnectionAttemptsRemaining--
					if concourseConnectionAttemptsRemaining <= 0 {
						monitor.Stop()
						Expect(err).ToNot(HaveOccurred())
						return
					}
					lg("failed to get status from concourse [", concourseConnectionAttemptsRemaining, " attempts remaining]", err)
				} else if done {
					concourseConnectionAttemptsRemaining = maxConcourseConnectionFailures
					lg("detected deployment job completed, stopping monitor")
					monitor.Stop()
					return
				}
			}
		}(maxConcourseConnectionFailures)

		report := monitor.Run()
		lg(report.String())
		Expect(report.Errors).To(BeEmpty(), "expected no errors")
		Expect(report.SuccessCount).To(BeNumerically(">", int64(0)), "expected at least one success")
		Expect(report.FailureCount).To(Equal(int64(0)), "expected 0 failures")
		Expect(report.WarningCount).To(BeNumerically("<=", int64(maxWarnings)), "expected at most %d warnings", maxWarnings)
	})
})
