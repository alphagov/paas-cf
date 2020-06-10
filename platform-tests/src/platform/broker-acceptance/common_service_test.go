package acceptance_test

import (
	"encoding/json"
	"fmt"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Common service tests", func() {

	Context("Shareable services", func() {

		shareableServices := map[string]bool{
			"elasticsearch": true,
			"influxdb":      true,
			"mysql":         false,
			"postgres":      false,
			"redis":         false,
			"aws-s3-bucket": false,
			"cdn-route":     false,
		}

		It("is service shareable", func() {

			retrieveServicesCommand := cf.Cf("curl", "/v2/services")

			Expect(retrieveServicesCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			var servicesCommandResp struct {
				TotalResults int `json:"total_results"`
				Resources    []struct {
					Entity struct {
						Label       string `json:"label"`
						Description string `json:"description"`
						Extra       string `json:"extra"`
					}
				}
			}

			err := json.Unmarshal(retrieveServicesCommand.Buffer().Contents(), &servicesCommandResp)
			Expect(err).NotTo(HaveOccurred())

			var message string
			//during the run of the pipeline we are running few acceptance tests in parallel
			//this can bring a total number of services in the CF instance to greater than 7 (the normal count)
			//hence, while checking for 'shareable' services - we need to filter out the fake services created
			//by other tests.
			// fake service can be identified by having a value 'fake service' in desciption field.
			fakeServicesCount := 0
			for _, service := range servicesCommandResp.Resources {

				if service.Entity.Description == "fake service" {
					fakeServicesCount++
					continue
				}

				message = fmt.Sprintf("verifying that %s backing service is shareable", service.Entity.Label)
				By(message)
				if shareableServices[service.Entity.Label] {
					Expect(service.Entity.Extra).To(ContainSubstring("\"shareable\":"),
						"Expected %s to have 'shareable' parameter", service.Entity.Label)
					Expect(service.Entity.Extra).To(ContainSubstring("\"shareable\": true"),
						"Expected %s to be shareable - i.e.: 'shareable' parameter set to 'true'", service.Entity.Label)
				} else {
					Expect(service.Entity.Extra).ToNot(ContainSubstring("\"shareable\": false"),
						"Expected %s NOT to have 'shareable' parameter or to be set to 'false'", service.Entity.Label)
				}
			}

			Expect(servicesCommandResp.TotalResults-fakeServicesCount).To(BeNumerically("==", len(shareableServices)), "the amount of services doesn't match")
		})
	})
})
