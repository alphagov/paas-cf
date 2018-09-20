package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListSpaceQuotas(t *testing.T) {
	Convey("List Space Quotas", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/space_quota_definitions", listSpaceQuotasPayloadPage1, "", 200, "", nil},
			{"GET", "/v2/space_quota_definitions_page_2", listSpaceQuotasPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaceQuotas, err := client.ListSpaceQuotas()
		So(err, ShouldBeNil)

		So(len(spaceQuotas), ShouldEqual, 2)
		So(spaceQuotas[0].Guid, ShouldEqual, "889aa2ed-a883-4cc0-abe5-804b2503f15d")
		So(spaceQuotas[0].Name, ShouldEqual, "test-1")
		So(spaceQuotas[0].NonBasicServicesAllowed, ShouldEqual, true)
		So(spaceQuotas[0].TotalServices, ShouldEqual, -1)
		So(spaceQuotas[0].TotalRoutes, ShouldEqual, 100)
		So(spaceQuotas[0].MemoryLimit, ShouldEqual, 102400)
		So(spaceQuotas[0].InstanceMemoryLimit, ShouldEqual, -1)
		So(spaceQuotas[0].AppInstanceLimit, ShouldEqual, -1)
		So(spaceQuotas[0].AppTaskLimit, ShouldEqual, -1)
		So(spaceQuotas[0].TotalServiceKeys, ShouldEqual, -1)
		So(spaceQuotas[0].TotalReservedRoutePorts, ShouldEqual, -1)
	})
}

func TestGetSpaceQuotaByName(t *testing.T) {
	Convey("Get Space Quota By Name", t, func() {
		setup(MockRoute{"GET", "/v2/space_quota_definitions", listSpaceQuotasPayloadPage2, "", 200, "q=name:test-2", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaceQuota, err := client.GetSpaceQuotaByName("test-2")
		So(err, ShouldBeNil)

		So(spaceQuota.Guid, ShouldEqual, "9ffd7c5c-d83c-4786-b399-b7bd54883977")
		So(spaceQuota.Name, ShouldEqual, "test-2")
		So(spaceQuota.NonBasicServicesAllowed, ShouldEqual, false)
		So(spaceQuota.TotalServices, ShouldEqual, 10)
		So(spaceQuota.TotalRoutes, ShouldEqual, 20)
		So(spaceQuota.MemoryLimit, ShouldEqual, 30)
		So(spaceQuota.InstanceMemoryLimit, ShouldEqual, 40)
		So(spaceQuota.AppInstanceLimit, ShouldEqual, 50)
		So(spaceQuota.AppTaskLimit, ShouldEqual, 60)
		So(spaceQuota.TotalServiceKeys, ShouldEqual, 70)
		So(spaceQuota.TotalReservedRoutePorts, ShouldEqual, 80)
	})
}

func TestCreateSpaceQuota(t *testing.T) {
	Convey("Create Space Quota", t, func() {
		setup(MockRoute{"POST", "/v2/space_quota_definitions", spaceQuotaPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaceQuotaRequest := SpaceQuotaRequest{
			Name:             "test-2",
			OrganizationGuid: "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
		}

		spaceQuota, err := client.CreateSpaceQuota(spaceQuotaRequest)
		So(err, ShouldBeNil)

		So(spaceQuota.Name, ShouldEqual, "test-2")
		So(spaceQuota.OrganizationGuid, ShouldEqual, "06dcedd4-1f24-49a6-adc1-cce9131a1b2c")

	})
}

func TestUpdateSpaceQuota(t *testing.T) {
	Convey("Create Update Quota", t, func() {
		setup(MockRoute{"PUT", "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977", spaceQuotaPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		spaceQuotaRequest := SpaceQuotaRequest{
			Name:             "test-2",
			OrganizationGuid: "06dcedd4-1f24-49a6-adc1-cce9131a1b2c",
		}

		spaceQuota, err := client.UpdateSpaceQuota("9ffd7c5c-d83c-4786-b399-b7bd54883977", spaceQuotaRequest)
		So(err, ShouldBeNil)

		So(spaceQuota.Name, ShouldEqual, "test-2")
		So(spaceQuota.OrganizationGuid, ShouldEqual, "06dcedd4-1f24-49a6-adc1-cce9131a1b2c")

	})
}

func TestAssignSpaceQuota(t *testing.T) {
	Convey("Assign Space Quota", t, func() {
		setup(MockRoute{"PUT", "/v2/space_quota_definitions/9ffd7c5c-d83c-4786-b399-b7bd54883977/spaces/8efd7c5c-d83c-4786-b399-b7bd548839e1", "", "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.AssignSpaceQuota("9ffd7c5c-d83c-4786-b399-b7bd54883977", "8efd7c5c-d83c-4786-b399-b7bd548839e1")
		So(err, ShouldBeNil)
	})
}
