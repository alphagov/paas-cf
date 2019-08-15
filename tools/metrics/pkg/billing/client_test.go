package billing_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gstruct"

	"code.cloudfoundry.org/lager"

	"github.com/jarcoal/httpmock"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/billing"
)

var _ = Describe("Client", func() {
	logger := lager.NewLogger("currency")
	logger.RegisterSink(lager.NewWriterSink(gbytes.NewBuffer(), lager.INFO))

	client := billing.NewClient(
		"https://billing.cloud.service.gov.uk",
		logger,
	)

	BeforeEach(func() {
		httpmock.Activate()
	})

	AfterEach(func() {
		httpmock.DeactivateAndReset()
	})

	Context("GetCostsByPlan", func() {
		It("Should get fail when not 200", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://billing.cloud.service.gov.uk/totals\z`,
				httpmock.NewStringResponder(400, ``),
			)

			_, err := client.GetCostsByPlan()

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).To(HaveOccurred())
			Expect(err).To(MatchError(ContainSubstring(
				"Billing client received statuscode 400",
			)))
		})

		It("Should get a costs by plan successfully", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://billing.cloud.service.gov.uk/totals\z`,
				httpmock.NewStringResponder(200, `[
					{
						"plan_guid": "b04825e6-9cfc-432a-abd1-5a64802f28c9",
						"cost": 123.45
					},
					{
						"plan_guid": "c14848e6-9cfc-432a-abd1-5a64802f28c9",
						"cost": 456.78
					}
				]`),
			)

			costs, err := client.GetCostsByPlan()

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).NotTo(HaveOccurred())

			Expect(costs).To(HaveLen(2))

			Expect(costs).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"PlanGUID": Equal("b04825e6-9cfc-432a-abd1-5a64802f28c9"),
					"Cost":     BeNumerically("==", 123.45),
				}),
			))

			Expect(costs).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"PlanGUID": Equal("c14848e6-9cfc-432a-abd1-5a64802f28c9"),
					"Cost":     BeNumerically("==", 456.78),
				}),
			))
		})
	})

	Context("GetPlans", func() {
		It("Should get fail when not 200", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://billing.cloud.service.gov.uk/pricing_plans`,
				httpmock.NewStringResponder(400, ``),
			)

			_, err := client.GetPlans()

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).To(HaveOccurred())
			Expect(err).To(MatchError(ContainSubstring(
				"Billing client received statuscode 400",
			)))
		})

		It("Should get plans successfully", func() {
			httpmock.RegisterResponder(
				"GET", `=~^https://billing.cloud.service.gov.uk/pricing_plans`,
				httpmock.NewStringResponder(200, `[
					{
						"plan_guid": "b04825e6-9cfc-432a-abd1-5a64802f28c9",
						"name": "a postgres small plan"
					},
					{
						"plan_guid": "c14848e6-9cfc-432a-abd1-5a64802f28c9",
						"name": "a postgres big plan"
					}
				]`),
			)

			plans, err := client.GetPlans()

			Expect(httpmock.GetTotalCallCount()).To(BeNumerically("==", 1))

			Expect(err).NotTo(HaveOccurred())

			Expect(plans).To(HaveLen(2))

			Expect(plans).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"PlanGUID": Equal("b04825e6-9cfc-432a-abd1-5a64802f28c9"),
					"Name":     Equal("a postgres small plan"),
				}),
			))

			Expect(plans).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"PlanGUID": Equal("c14848e6-9cfc-432a-abd1-5a64802f28c9"),
					"Name":     Equal("a postgres big plan"),
				}),
			))
		})
	})
})
