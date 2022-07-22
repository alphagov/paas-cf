package main

import (
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"

	uaaclient "github.com/cloudfoundry-community/go-uaa"

	m "github.com/alphagov/paas-cf/tools/metrics/pkg/metrics"
)

var _ = Describe("UAA", func() {

	MinusOneDay := -1 * 24 * time.Hour
	OneDayAgo := time.Now().Add(MinusOneDay)
	ThirtyOneDaysAgo := time.Now().Add(MinusOneDay * 31)

	Context("Users Aggregation", func() {
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
					"Kind":  Equal(m.Gauge),
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
					"Kind":  Equal(m.Gauge),
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
					"Kind":  Equal(m.Gauge),
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
					"Kind":  Equal(m.Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("microsoft"),
					})),
				}),
			))
		})
	})

	Context("Active Users (logged in within 30 days)", func() {
		It("Should select active users", func() {
			activeUsers := []uaaclient.User{{
				Origin:        "uaa",
				LastLogonTime: int(OneDayAgo.Unix() * 1000),
			}}

			Expect(UAAActiveUsers(activeUsers)).To(HaveLen(1))
		})

		It("Should reject inactive users", func() {
			inactiveUsers := []uaaclient.User{{
				Origin:        "uaa",
				LastLogonTime: int(ThirtyOneDaysAgo.Unix() * 1000),
			}}

			Expect(UAAActiveUsers(inactiveUsers)).To(HaveLen(0))
		})

		It("Should select active and reject inactive users", func() {
			users := []uaaclient.User{{
				Origin:        "google",
				LastLogonTime: int(OneDayAgo.Unix() * 1000),
			}, {
				Origin:        "uaa",
				LastLogonTime: int(ThirtyOneDaysAgo.Unix() * 1000),
			}}

			activeUsers := UAAActiveUsers(users)

			Expect(activeUsers).To(HaveLen(1))
			Expect(activeUsers[0].Origin).To(Equal("google"))
		})
	})

	Context("Active Users Aggregation (logged in within 30 days)", func() {
		It("Should select active users as gauges", func() {
			users := []uaaclient.User{{
				Origin:        "uaa",
				LastLogonTime: int(OneDayAgo.Unix() * 1000),
			}}

			gauges := UAAActiveUsersByOriginGauges(users)

			Expect(gauges).To(HaveLen(1))
			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.active.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(m.Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("uaa"),
					})),
				}),
			))
		})

		It("Should reject inactive users as gauges", func() {
			users := []uaaclient.User{{
				Origin:        "uaa",
				LastLogonTime: int(ThirtyOneDaysAgo.Unix() * 1000),
			}}

			gauges := UAAActiveUsersByOriginGauges(users)

			Expect(gauges).To(HaveLen(0))
		})

		It("Should select active and reject inactive users as gauges", func() {
			users := []uaaclient.User{{
				Origin:        "google",
				LastLogonTime: int(OneDayAgo.Unix() * 1000),
			}, {
				Origin:        "uaa",
				LastLogonTime: int(ThirtyOneDaysAgo.Unix() * 1000),
			}}

			gauges := UAAActiveUsersByOriginGauges(users)

			Expect(gauges).To(HaveLen(1))
			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.active.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(m.Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("google"),
					})),
				}),
			))
		})

		It("Should select active and reject inactive users as gauges for many users", func() {
			users := []uaaclient.User{{
				Origin:        "google",
				LastLogonTime: int(OneDayAgo.Unix() * 1000),
			}, {
				Origin:        "google",
				LastLogonTime: int(time.Now().Add(MinusOneDay*60).Unix() * 1000),
			}, {
				Origin:        "microsoft",
				LastLogonTime: int(time.Now().Add(MinusOneDay*2).Unix() * 1000),
			}, {
				Origin:        "microsoft",
				LastLogonTime: int(time.Now().Add(MinusOneDay*91).Unix() * 1000),
			}, {
				Origin:        "uaa",
				LastLogonTime: int(time.Now().Add(MinusOneDay*2).Unix() * 1000),
			}, {
				Origin:        "uaa",
				LastLogonTime: int(time.Now().Add(MinusOneDay*31).Unix() * 1000),
			}}

			gauges := UAAActiveUsersByOriginGauges(users)

			Expect(gauges).To(HaveLen(3))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.active.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(m.Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("google"),
					})),
				}),
			))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.active.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(m.Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("microsoft"),
					})),
				}),
			))

			Expect(gauges).To(ContainElement(
				MatchFields(IgnoreExtras, Fields{
					"Name":  Equal("uaa.active.users"),
					"Unit":  Equal("count"),
					"Kind":  Equal(m.Gauge),
					"Value": BeNumerically("==", 1),
					"Tags": ContainElement(MatchFields(IgnoreExtras, Fields{
						"Label": Equal("origin"), "Value": Equal("uaa"),
					})),
				}),
			))
		})
	})
})
