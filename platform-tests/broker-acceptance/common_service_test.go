package broker_acceptance_test

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/google/uuid"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Common service tests", func() {
	Context("Shareable services", func() {
		shareableServices := map[string]bool{
			"autoscaler":    false,
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

	Context("Service offerings", func() {
		It("has a valid id", func() {
			offerings, err := cfClient.ListServices()
			Expect(err).NotTo(HaveOccurred())

			invalidServiceOfferings := []string{}
			for _, offering := range offerings {
				if strings.HasPrefix(offering.Label, "CATS-") {
					continue
				}

				if _, err := uuid.Parse(offering.UniqueID); err != nil {
					invalidServiceOfferings = append(invalidServiceOfferings, offering.Label)
				}
			}

			Expect(invalidServiceOfferings).To(
				BeEmpty(), "All service offerings should have a GUID unique ID",
			)
		})
	})

	Context("Service plans", func() {
		It("has a valid ID", func() {
			plans, err := cfClient.ListServicePlans()

			Expect(err).NotTo(HaveOccurred())

			invalidServicePlans := []string{}
			for _, plan := range plans {
				if plan.Name == "shared" {
					continue
				}

				if strings.HasPrefix(plan.Name, "fake-") {
					continue
				}

				if _, err := uuid.Parse(plan.UniqueId); err != nil {
					invalidServicePlans = append(invalidServicePlans, plan.Name)
				}
			}

			Expect(invalidServicePlans).To(
				BeEmpty(), "All service plans should have a GUID unique ID",
			)
		})
	})
})
