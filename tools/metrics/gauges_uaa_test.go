package main

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"

	uaaclient "github.com/cloudfoundry-community/go-uaa"
)

var _ = Describe("UAA", func() {
	Context("Aggregation", func() {
		It("Should aggregate users correctly for no users", func() {
			gauges := UAAUsersByOriginGauges([]uaaclient.User{})

			Expect(gauges).To(HaveLen(0))
		})

		It("Should aggregate users correctly for a UAA user", func() {
			gauges := UAAUsersByOriginGauges([]uaaclient.User{
				{Origin: "uaa"},
			})

			Expect(gauges).To(HaveLen(1))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("uaa"),
					})),
				}),
			))
		})

		It("Should aggregate users correctly for some UAA users", func() {
			gauges := UAAUsersByOriginGauges([]uaaclient.User{
				{Origin: "uaa"}, {Origin: "uaa"},
				{Origin: "google"}, {Origin: "microsoft"},
				{Origin: "uaa"}, {Origin: "uaa"}, {Origin: "google"},
			})

			Expect(gauges).To(HaveLen(3))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(Gauge),
					"Value": BeNumerically("==", 4),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("uaa"),
					})),
				}),
			))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(Gauge),
					"Value": BeNumerically("==", 2),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("google"),
					})),
				}),
			))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("microsoft"),
					})),
				}),
			))
		})
	})
})
