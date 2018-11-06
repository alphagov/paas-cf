package acceptance_test

import (
	"fmt"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"

	"encoding/json"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
)

var _ = Describe("Configured routes and domains", func() {
	It("have a wildcard route configured for each non-internal shared domain", func() {
		workflowhelpers.AsUser(testContext.AdminUserContext(), testConfig.DefaultTimeoutDuration(), func() {

			sharedDomainsCommand := cf.Cf("curl", "/v2/shared_domains")
			Expect(sharedDomainsCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))

			var sharedDomainsResp struct {
				Resources []struct {
					Metadata struct {
						GUID string
					}
					Entity struct {
						Name     string
						Internal bool
					}
				}
			}

			err := json.Unmarshal(sharedDomainsCommand.Buffer().Contents(), &sharedDomainsResp)
			Expect(err).NotTo(HaveOccurred())

			for _, sharedDomain := range sharedDomainsResp.Resources {
				if sharedDomain.Entity.Internal == true {
					continue
				}

				routesCommand := cf.Cf("curl",
					fmt.Sprintf("/v2/routes?q=host:*&q=domain_guid:%s", sharedDomain.Metadata.GUID),
				)
				Expect(routesCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				var routesResp struct {
					TotalResults int `json:"total_results"`
					Resources    []struct {
						Entity struct {
							SpaceURL string `json:"space_url"`
						}
					}
				}

				err := json.Unmarshal(routesCommand.Buffer().Contents(), &routesResp)
				Expect(err).NotTo(HaveOccurred())
				Expect(routesResp.TotalResults).To(
					BeNumerically("==", 1),
					"No wildcard '*' route set for shared domain '%s'", sharedDomain.Entity.Name,
				)

				// Check that the route is in the desired org
				spaceCommand := cf.Cf("curl", routesResp.Resources[0].Entity.SpaceURL)
				Expect(spaceCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				var spaceResp struct {
					Entity struct {
						OrganizationURL string `json:"organization_url"`
					}
				}
				err = json.Unmarshal(spaceCommand.Buffer().Contents(), &spaceResp)
				Expect(err).NotTo(HaveOccurred())

				orgCommand := cf.Cf("curl", spaceResp.Entity.OrganizationURL)
				Expect(orgCommand.Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				var orgResp struct {
					Entity struct {
						Name string
					}
				}
				err = json.Unmarshal(orgCommand.Buffer().Contents(), &orgResp)
				Expect(err).NotTo(HaveOccurred())

				expectedOrgName = "govuk-paas"
				Expect(orgResp.Entity.Name).To(Equal(expectedOrgName),
					"Expected org for wildcard '*' in shared domain '%s' to be '%s', got '%s'",
					sharedDomain.Entity.Name, expectedOrgName, orgResp.Entity.Name,
				)
			}
		})
	})
})
