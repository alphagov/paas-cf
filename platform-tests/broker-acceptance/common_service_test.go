package broker_acceptance_test

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
			"mysql":         true,
			"postgres":      true,
			"redis":         true,
			"aws-s3-bucket": true,
			"cdn-route":     false,
		}

		It("is service shareable", func() {

			retrieveServicesCommand := cf.Cf("curl", "/v3/service_offerings")

			Expect(retrieveServicesCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			var servicesCommandResp struct {
				Pagination struct {
					TotalResults int `json:"total_results"`
				}
				Resources []struct {
					Name          string `json:"name"`
					Description   string `json:"description"`
					BrokerCatalog struct {
						Metadata struct {
							Shareable bool `json:"shareable"`
						}
					} `json:"broker_catalog"`
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

				if service.Description == "fake service" {
					fakeServicesCount++
					continue
				}

				message = fmt.Sprintf("verifying that %s backing service is shareable", service.Name)
				By(message)
				if shareableServices[service.Name] {
					Expect(service.BrokerCatalog.Metadata.Shareable).NotTo(BeNil(),
						"Expected %s to have 'shareable' parameter", service.Name)

					Expect(service.BrokerCatalog.Metadata.Shareable).To(BeTrue(),
						"Expected %s to be shareable - i.e.: 'shareable' parameter set to 'true'", service.Name)
				} else {
					Expect(service.BrokerCatalog.Metadata.Shareable).To(BeFalse(),
						"Expected %s NOT to have 'shareable' parameter or to be set to 'false'", service.Name)
				}
			}

			Expect(servicesCommandResp.Pagination.TotalResults-fakeServicesCount).To(BeNumerically("==", len(shareableServices)), "the amount of services doesn't match")
		})
	})
})
