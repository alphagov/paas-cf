package main

import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"

	"github.com/alphagov/paas-cf/tools/metrics/pkg/billing"
	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("Billing Gauges", func() {
	It("should return zero for no costs", func() {
		totalCosts := []billing.CostByPlan{}
		gauges := CostsByPlanGauges(totalCosts, []billing.Plan{})

		Expect(gauges).To(HaveLen(0))
	})

	It("Should return the correct costs for a plan", func() {
		plans := []billing.Plan{
			{
				PlanGUID: "11f779fa-425c-4c86-9530-d0aebcb3c3e6",
				Name:     "app",
			},
			{
				PlanGUID: "5f2eec8a-0cad-4ab9-b81e-d6adade2fd42",
				Name:     "task",
			},
			{
				PlanGUID: "24efab31-8cbd-47c0-8513-a9345f3c512b",
				Name:     "postgres tiny",
			},
			{
				PlanGUID: "69977068-8ef5-4172-bfdb-e8cea3c14d01",
				Name:     "postgres small",
			},
			{
				PlanGUID: "3a51701c-eef3-447c-882b-907ad2bcb7ab",
				Name:     "unknown-plan",
			},
		}

		totalCosts := []billing.CostByPlan{
			{
				PlanGUID: "11f779fa-425c-4c86-9530-d0aebcb3c3e6",
				Cost:     2.1,
			},
			{
				PlanGUID: "24efab31-8cbd-47c0-8513-a9345f3c512b",
				Cost:     0.02,
			},
			{
				PlanGUID: "3a51701c-eef3-447c-882b-907ad2bcb7ab",
				Cost:     0.06,
			},
			{
				PlanGUID: "5f2eec8a-0cad-4ab9-b81e-d6adade2fd42",
				Cost:     6.43,
			},
			{
				PlanGUID: "69977068-8ef5-4172-bfdb-e8cea3c14d01",
				Cost:     2.09,
			},
		}
		gauges := CostsByPlanGauges(totalCosts, plans)

		Expect(gauges).To(HaveLen(5))

		Expect(gauges).To(ContainElement(
			MatchFields(IgnoreExtras, Fields{
				"Name":  Equal("billing.total.costs"),
				"Unit":  Equal("pounds"),
				"Kind":  Equal(m.Gauge),
				"Value": Equal(2.09),
				"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
					"Label": Equal("plan_guid"),
					"Value": Equal("69977068-8ef5-4172-bfdb-e8cea3c14d01"),
				})),
			}),
		))

		Expect(gauges).To(ContainElement(
			MatchFields(IgnoreExtras, Fields{
				"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
					"Label": Equal("name"), "Value": Equal("postgres small"),
				})),
			}),
		))
	})

	It("Should return the correct rates for currencies", func() {
		rates := []billing.CurrencyRate{
			{Code: "USD", Rate: 0.9},
			{Code: "GBP", Rate: 1},
		}

		metrics := CurrencyRateGauges(rates)

		Expect(metrics).To(HaveLen(2))

		Expect(metrics).To(ContainElement(
			MatchFields(IgnoreExtras, Fields{
				"Name":  Equal("billing.currency.configured"),
				"Unit":  Equal("ratio"),
				"Kind":  Equal(m.Gauge),
				"Value": BeNumerically("==", 1),
				"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
					"Label": Equal("code"),
					"Value": Equal("GBP"),
				})),
			}),
		))

		Expect(metrics).To(ContainElement(
			MatchFields(IgnoreExtras, Fields{
				"Name":  Equal("billing.currency.configured"),
				"Unit":  Equal("ratio"),
				"Kind":  Equal(m.Gauge),
				"Value": BeNumerically("==", 0.9),
				"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
					"Label": Equal("code"),
					"Value": Equal("USD"),
				})),
			}),
		))
	})
})
