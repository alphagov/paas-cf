package cfclient

import (
	. "github.com/smartystreets/goconvey/convey"
	"net/http"
	"testing"
)

func TestMappingAppAndRoute(t *testing.T) {
	Convey("Mapping app and route", t, func() {
		setup(MockRoute{"POST", "/v2/route_mappings", postRouteMappingsPayload, "", http.StatusCreated, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		mappingRequest := RouteMappingRequest{AppGUID: "fa23ddfc-b635-4205-8283-844c53122888", RouteGUID: "e00fb1e1-f7d4-4e36-9912-f76a587e9858", AppPort: 8888}

		mapping, err := client.MappingAppAndRoute(mappingRequest)
		So(err, ShouldBeNil)
		So(mapping.Guid, ShouldEqual, "f869fa46-22b1-40ee-b491-58e321345528")
		So(mapping.AppGUID, ShouldEqual, "fa23ddfc-b635-4205-8283-844c53122888")
		So(mapping.RouteGUID, ShouldEqual, "e00fb1e1-f7d4-4e36-9912-f76a587e9858")
	})
}

func TestListRouteMappings(t *testing.T) {
	Convey("List route mappings", t, func() {
		setup(MockRoute{"GET", "/v2/route_mappings", listRouteMappingsPayload, "", http.StatusOK, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		routeMappings, err := client.ListRouteMappings()
		So(err, ShouldBeNil)

		So(len(routeMappings), ShouldEqual, 2)
		So(routeMappings[0].Guid, ShouldEqual, "63603ed7-bd4a-4475-a371-5b34381e0cf7")
		So(routeMappings[1].Guid, ShouldEqual, "63603ed7-bd4a-4475-a371-5b34381e0cf8")
		So(routeMappings[0].AppGUID, ShouldEqual, "ee8b175a-2228-4931-be8a-1f6445bd63bc")
		So(routeMappings[1].AppGUID, ShouldEqual, "ee8b175a-2228-4931-be8a-1f6445bd63bd")
		So(routeMappings[0].RouteGUID, ShouldEqual, "eb1c4fcd-7d6d-41d2-bd2f-5811f53b6677")
		So(routeMappings[1].RouteGUID, ShouldEqual, "eb1c4fcd-7d6d-41d2-bd2f-5811f53b6678")
	})
}

func TestGetRouteMappingByGuid(t *testing.T) {
	Convey("Get route mapping by guid", t, func() {
		setup(MockRoute{"GET", "/v2/route_mappings/93eb2527-81b9-4e15-8ba0-2fd8dd8c0c1c", getRouteMappingByGuidPayload, "", http.StatusOK, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		routeMapping, err := client.GetRouteMappingByGuid("93eb2527-81b9-4e15-8ba0-2fd8dd8c0c1c")
		So(err, ShouldBeNil)
		So(routeMapping.Guid, ShouldEqual, "93eb2527-81b9-4e15-8ba0-2fd8dd8c0c1c")
		So(routeMapping.AppGUID, ShouldEqual, "caf3e3a9-1f64-46d3-a0d5-a3d4ae3f4be4")
		So(routeMapping.RouteGUID, ShouldEqual, "34931bf5-79d0-4303-b082-df023b3305ce")
	})
}

func TestDeleteRouteMapping(t *testing.T) {
	Convey("Delete route mapping", t, func() {
		setup(MockRoute{"DELETE", "/v2/route_mappings/93eb2527-81b9-4e15-8ba0-2fd8dd8c0c1c", "", "", http.StatusNoContent, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteRouteMapping("93eb2527-81b9-4e15-8ba0-2fd8dd8c0c1c")
		So(err, ShouldBeNil)
	})
}
