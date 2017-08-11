package api

import (
	"fmt"
	"net/url"
	"os"
	"time"

	"github.com/cloudfoundry-community/go-cfclient"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

const (
	maxConcourseConnectionFailures = 5
)

func lg(things ...interface{}) {
	fmt.Fprintln(os.Stdout, things...)
}

var _ = Describe("API Availability Monitoring", func() {

	It("should have uninterupted access to cloudfoundry api during deploy", func() {

		cfg := &cfclient.Config{
			ApiAddress:        fmt.Sprintf("https://api.%s", os.Getenv("SYSTEM_DNS_ZONE_NAME")),
			Username:          os.Getenv("CF_USER"),
			Password:          os.Getenv("CF_PASS"),
			SkipSslValidation: os.Getenv("SKIP_SSL_VALIDATION") == "true",
		}
		Expect(cfg.ApiAddress).ToNot(Equal(""), "SYSTEM_DNS_ZONE_NAME environment variable must be set")
		Expect(cfg.Username).ToNot(Equal(""), "CF_USER environment variable must be set")
		Expect(cfg.Password).ToNot(Equal(""), "CF_PASS environment variable must be set")

		deployment := &Deployment{
			AtcAddress: os.Getenv("CONCOURSE_ATC_URL"),
			Password:   os.Getenv("CONCOURSE_ATC_PASSWORD"),
			Username:   os.Getenv("CONCOURSE_ATC_USERNAME"),
			Version:    os.Getenv("PIPELINE_TRIGGER_VERSION"),
			Team:       "main",
		}
		Expect(deployment.AtcAddress).ToNot(Equal(""), "CONCOURSE_ATC_URL environment variable must be set")
		Expect(deployment.Password).ToNot(Equal(""), "CONCOURSE_ATC_PASSWORD environment variable must be set")
		Expect(deployment.Username).ToNot(Equal(""), "CONCOURSE_ATC_USERNAME environment variable must be set")
		Expect(deployment.Version).ToNot(Equal(""), "PIPELINE_TRIGGER_VERSION environment variable must be set")

		monitor := NewMonitor(cfg)

		monitor.Add("Listing all apps in a space", func(cf *cfclient.Client) error {
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

		monitor.Add("Fetching detailed app information", func(cf *cfclient.Client) error {
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
		Expect(report.Successes).To(BeNumerically(">", 0), "expected at least one success")
		Expect(report.Failures).To(Equal(int64(0)), "expected 0 failures")

	})
})
