package helpers

import (
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"sort"
	"time"

	"github.com/concourse/atc"
	"github.com/concourse/go-concourse/concourse"
)

const (
	teamName     = "main"
	pipelineName = "create-cloudfoundry"
	jobName      = "post-deploy"
	resourceName = "pipeline-trigger"
)

type byStartTime []atc.Build

func (a byStartTime) Len() int           { return len(a) }
func (a byStartTime) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a byStartTime) Less(i, j int) bool { return a[i].StartTime > a[j].StartTime }

type basicAuthTransport struct {
	username string
	password string
	base     http.RoundTripper
}

func (t basicAuthTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	r.SetBasicAuth(t.username, t.password)
	return t.base.RoundTrip(r)
}

func newConcourseClient() concourse.Client {
	var transport http.RoundTripper

	tlsConfig := &tls.Config{InsecureSkipVerify: os.Getenv("SKIP_SSL_VALIDATION") == "true"}
	transport = &http.Transport{
		TLSClientConfig: tlsConfig,
		Dial: (&net.Dialer{
			Timeout: 10 * time.Second,
		}).Dial,
		Proxy: http.ProxyFromEnvironment,
	}

	client := concourse.NewClient(
		mustGetenv(2, "CONCOURSE_WEB_URL"),
		&http.Client{
			Transport: basicAuthTransport{
				username: mustGetenv(2, "CONCOURSE_WEB_USERNAME"),
				password: mustGetenv(2, "CONCOURSE_WEB_PASSWORD"),
				base:     transport,
			},
		},
	)
	return client
}

// Deployment represents a full run of a concourse pipeline.
type Deployment struct {
	Version string
	client  concourse.Client
}

func ConcourseDeployment() *Deployment {
	return &Deployment{
		Version: mustGetenv(1, "PIPELINE_TRIGGER_VERSION"),
		client:  newConcourseClient(),
	}
}

func (d *Deployment) Complete() (bool, error) {
	team := d.client.Team(teamName)
	builds, err := buildsWithVersion(team, pipelineName, resourceName, d.Version)
	if err != nil {
		return false, err
	}
	if len(builds) != 0 && (builds[0].Status == "succeeded" || builds[0].Status == "failed") {
		return true, nil
	}
	return false, nil
}

func buildsWithVersion(team concourse.Team, pipelineName, resourceName, resourceVersion string) ([]atc.Build, error) {
	var resourceVersionID int

	page := concourse.Page{
		Since: 0,
		Until: 0,
		Limit: 10,
	}

	resourceVersions, _, resourceExists, err := team.ResourceVersions(pipelineName, resourceName, page)
	if err != nil {
		return nil, err
	} else if !resourceExists {
		return nil, fmt.Errorf("Resource: %v did not exist in Concourse", resourceVersions)
	}

	for _, version := range resourceVersions {
		if resourceVersion == version.Version["number"] {
			resourceVersionID = version.ID
		}
	}
	if resourceVersionID == 0 {
		return nil, fmt.Errorf("Resource: %s with version: %s did not exist in Concourse", resourceName, resourceVersion)
	}

	builds, _, err := team.BuildsWithVersionAsInput(pipelineName, resourceName, resourceVersionID)
	if err != nil {
		return nil, err
	}

	return filterBuildsByNameAndSortByTime(builds, jobName), nil
}

func filterBuildsByNameAndSortByTime(builds []atc.Build, jobName string) []atc.Build {
	var filteredBuilds []atc.Build
	for _, build := range builds {
		if build.JobName == jobName {
			filteredBuilds = append(filteredBuilds, build)
		}
	}
	sort.Sort(byStartTime(filteredBuilds))
	return filteredBuilds
}
