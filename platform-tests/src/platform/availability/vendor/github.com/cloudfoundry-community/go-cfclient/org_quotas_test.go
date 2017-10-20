package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListOrgQuotas(t *testing.T) {
	Convey("List Org Quotas", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/quota_definitions", listOrgQuotasPayloadPage1, "", 200, "", nil},
			{"GET", "/v2/quota_definitions_page_2", listOrgQuotasPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgQuotas, err := client.ListOrgQuotas()
		So(err, ShouldBeNil)

		So(len(orgQuotas), ShouldEqual, 2)
		So(orgQuotas[0].Guid, ShouldEqual, "6f9d3100-44ab-49e2-a4f8-9d7d67651ae7")
		So(orgQuotas[0].Name, ShouldEqual, "test-1")
		So(orgQuotas[0].NonBasicServicesAllowed, ShouldEqual, true)
		So(orgQuotas[0].TotalServices, ShouldEqual, -1)
		So(orgQuotas[0].TotalRoutes, ShouldEqual, 100)
		So(orgQuotas[0].TotalPrivateDomains, ShouldEqual, -1)
		So(orgQuotas[0].MemoryLimit, ShouldEqual, 102400)
		So(orgQuotas[0].TrialDBAllowed, ShouldEqual, false)
		So(orgQuotas[0].InstanceMemoryLimit, ShouldEqual, -1)
		So(orgQuotas[0].AppInstanceLimit, ShouldEqual, -1)
		So(orgQuotas[0].AppTaskLimit, ShouldEqual, -1)
		So(orgQuotas[0].TotalServiceKeys, ShouldEqual, -1)
		So(orgQuotas[0].TotalReservedRoutePorts, ShouldEqual, -1)
	})
}

func TestGetOrgQuotaByName(t *testing.T) {
	Convey("Get Org Quota By Name", t, func() {
		setup(MockRoute{"GET", "/v2/quota_definitions", listOrgQuotasPayloadPage2, "", 200, "q=name:default2", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		orgQuota, err := client.GetOrgQuotaByName("default2")
		So(err, ShouldBeNil)

		So(orgQuota.Guid, ShouldEqual, "a537761f-9d93-4b30-af17-3d73dbca181b")
		So(orgQuota.Name, ShouldEqual, "test-2")
		So(orgQuota.NonBasicServicesAllowed, ShouldEqual, false)
		So(orgQuota.TotalServices, ShouldEqual, 10)
		So(orgQuota.TotalRoutes, ShouldEqual, 20)
		So(orgQuota.TotalPrivateDomains, ShouldEqual, 30)
		So(orgQuota.MemoryLimit, ShouldEqual, 40)
		So(orgQuota.TrialDBAllowed, ShouldEqual, true)
		So(orgQuota.InstanceMemoryLimit, ShouldEqual, 50)
		So(orgQuota.AppInstanceLimit, ShouldEqual, 60)
		So(orgQuota.AppTaskLimit, ShouldEqual, 70)
		So(orgQuota.TotalServiceKeys, ShouldEqual, 80)
		So(orgQuota.TotalReservedRoutePorts, ShouldEqual, 90)
	})
}
