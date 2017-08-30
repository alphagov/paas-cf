package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServicePlanVisibilities(t *testing.T) {
	Convey("List service plan visibilities", t, func() {
		setup(MockRoute{"GET", "/v2/service_plan_visibilities", listServicePlanVisibilitiesPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		servicePlanVisibilities, err := client.ListServicePlanVisibilities()
		So(err, ShouldBeNil)

		So(len(servicePlanVisibilities), ShouldEqual, 2)
		So(servicePlanVisibilities[0].Guid, ShouldEqual, "d1b5ea55-f354-4f43-b52e-53045747adb9")
		So(servicePlanVisibilities[0].ServicePlanGuid, ShouldEqual, "62cb572c-e9ca-4c9f-b822-8292db1d9a96")
		So(servicePlanVisibilities[0].OrganizationGuid, ShouldEqual, "81df84f3-8ce0-4c92-990a-3760b6ff66bd")
		So(servicePlanVisibilities[0].ServicePlanUrl, ShouldEqual, "/v2/service_plans/62cb572c-e9ca-4c9f-b822-8292db1d9a96")
		So(servicePlanVisibilities[0].OrganizationUrl, ShouldEqual, "/v2/organizations/81df84f3-8ce0-4c92-990a-3760b6ff66bd")
	})
}

func TestCreateServicePlanVisibility(t *testing.T) {
	Convey("Create service plan visibility", t, func() {
		setup(MockRoute{"POST", "/v2/service_plan_visibilities", postServicePlanVisibilityPayload, "", 201, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		servicePlanVisibility, err := client.CreateServicePlanVisibility("ab5780a9-ac8e-4412-9496-4512e865011a", "55d0ff39-dac9-431f-ba6d-83f37381f1c3")
		So(err, ShouldBeNil)

		So(servicePlanVisibility.Guid, ShouldEqual, "f740b01a-4afe-4435-aedd-0a8308a7e7d6")
		So(servicePlanVisibility.ServicePlanGuid, ShouldEqual, "ab5780a9-ac8e-4412-9496-4512e865011a")
		So(servicePlanVisibility.OrganizationGuid, ShouldEqual, "55d0ff39-dac9-431f-ba6d-83f37381f1c3")
		So(servicePlanVisibility.ServicePlanUrl, ShouldEqual, "/v2/service_plans/ab5780a9-ac8e-4412-9496-4512e865011a")
		So(servicePlanVisibility.OrganizationUrl, ShouldEqual, "/v2/organizations/55d0ff39-dac9-431f-ba6d-83f37381f1c3")
	})
}
