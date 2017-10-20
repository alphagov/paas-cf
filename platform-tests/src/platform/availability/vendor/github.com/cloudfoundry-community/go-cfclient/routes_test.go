package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListRoutes(t *testing.T) {
	Convey("List Routes", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/routes", listRoutesPayloadPage1, "", 200, "", nil},
			{"GET", "/v2/routes_page_2", listRoutesPayloadPage2, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		routes, err := client.ListRoutes()
		So(err, ShouldBeNil)

		So(len(routes), ShouldEqual, 2)
		So(routes[0].Guid, ShouldEqual, "24707add-83b8-4fd8-a8f4-b7297199c805")
		So(routes[0].Host, ShouldEqual, "test-1")
		So(routes[0].Path, ShouldEqual, "/foo")
		So(routes[0].DomainGuid, ShouldEqual, "0b183484-45cc-4855-94d4-892f80f20c13")
		So(routes[0].SpaceGuid, ShouldEqual, "494d8b64-8181-4183-a6d3-6279db8fec6e")
		So(routes[0].ServiceInstanceGuid, ShouldEqual, "")
		So(routes[0].Port, ShouldEqual, 0)
	})
}

func TestCreateTcpRoute(t *testing.T) {
	Convey("Create TCP Route", t, func() {
		setup(MockRoute{"POST", "/v2/routes", createRoute, "", 201, "generate_port=true", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		routeRequest := RouteRequest{
			DomainGuid: "08167353-32da-4ed9-9ef5-aa7b31bbc009",
			SpaceGuid:  "b65a9a76-8c55-460b-9162-18b396da66cf",
		}

		route, err := client.CreateTcpRoute(routeRequest)
		So(err, ShouldBeNil)

		So(route.SpaceGuid, ShouldEqual, "b65a9a76-8c55-460b-9162-18b396da66cf")
		So(route.DomainGuid, ShouldEqual, "08167353-32da-4ed9-9ef5-aa7b31bbc009")
		So(route.Port, ShouldEqual, 1099)

	})
}
