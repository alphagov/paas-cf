package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServicePlans(t *testing.T) {
	Convey("List Service Plans", t, func() {
		setup(MockRoute{"GET", "/v2/service_plans", listServicePlansPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		servicePlans, err := client.ListServicePlans()
		So(err, ShouldBeNil)

		So(len(servicePlans), ShouldEqual, 1)
		So(servicePlans[0].Guid, ShouldEqual, "6fecf53b-7553-4cb3-b97e-930f9c4e3385")
		So(servicePlans[0].Name, ShouldEqual, "name-1575")
		So(servicePlans[0].Description, ShouldEqual, "desc-109")
		So(servicePlans[0].ServiceGuid, ShouldEqual, "1ccab853-87c9-45a6-bf99-603032d17fe5")
		So(servicePlans[0].Extra, ShouldBeNil)
		So(servicePlans[0].UniqueId, ShouldEqual, "1bc2884c-ee3d-4f82-a78b-1a657f79aeac")
		So(servicePlans[0].Public, ShouldEqual, true)
		So(servicePlans[0].Active, ShouldEqual, true)
		So(servicePlans[0].Bindable, ShouldEqual, true)
		So(servicePlans[0].ServiceUrl, ShouldEqual, "/v2/services/1ccab853-87c9-45a6-bf99-603032d17fe5")
		So(servicePlans[0].ServiceInstancesUrl, ShouldEqual, "/v2/service_plans/6fecf53b-7553-4cb3-b97e-930f9c4e3385/service_instances")
	})
}
