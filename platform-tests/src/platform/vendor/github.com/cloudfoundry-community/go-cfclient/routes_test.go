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

func TestCreateRoute(t *testing.T) {
	Convey("Create HTTP Route", t, func() {
		setup(MockRoute{"POST", "/v2/routes", createRoute, "", 201, "", nil}, t)
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
			Host:       "foo-host",
		}

		route, err := client.CreateRoute(routeRequest)
		So(err, ShouldBeNil)

		So(route.Guid, ShouldEqual, "b3fe6f31-e897-4e02-b49e-263ca96b4e3a")
		So(route.SpaceGuid, ShouldEqual, "b65a9a76-8c55-460b-9162-18b396da66cf")
		So(route.DomainGuid, ShouldEqual, "08167353-32da-4ed9-9ef5-aa7b31bbc009")
		So(route.Host, ShouldEqual, "foo-host")
		So(route.Port, ShouldEqual, 0)
		So(route.Path, ShouldEqual, "")
		So(route.ServiceInstanceGuid, ShouldEqual, "")
	})
}

func TestCreateTcpRoute(t *testing.T) {
	Convey("Create TCP Route", t, func() {
		setup(MockRoute{"POST", "/v2/routes", createTcpRoute, "", 201, "generate_port=true", nil}, t)
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

		So(route.Guid, ShouldEqual, "78fe5006-1d1c-41ba-94de-eb7002241b82")
		So(route.SpaceGuid, ShouldEqual, "b65a9a76-8c55-460b-9162-18b396da66cf")
		So(route.DomainGuid, ShouldEqual, "08167353-32da-4ed9-9ef5-aa7b31bbc009")
		So(route.Port, ShouldEqual, 1099)
	})
}

func TestBindRoute(t *testing.T) {
	Convey("Bind route", t, func() {
		Convey("When a successful status code is returned", func() {
			setup(MockRoute{"PUT", "/v2/routes/7803de15-a20f-4dea-bf17-37de56629582/apps/ce5d0e27-3048-4024-80cb-fafbae9c3161", bindRoute, "", 201, "", nil}, t)
			defer teardown()
			c := &Config{
				ApiAddress: server.URL,
				Token:      "foobar",
			}
			client, err := NewClient(c)
			So(err, ShouldBeNil)

			err = client.BindRoute("7803de15-a20f-4dea-bf17-37de56629582", "ce5d0e27-3048-4024-80cb-fafbae9c3161")
			So(err, ShouldBeNil)

		})
		Convey("When an error status code is returned", func() {
			setup(MockRoute{"PUT", "/v2/routes/7803de15-a20f-4dea-bf17-37de56629582/apps/ce5d0e27-3048-4024-80cb-fafbae9c3161", "", "", 400, "", nil}, t)
			defer teardown()
			c := &Config{
				ApiAddress: server.URL,
				Token:      "foobar",
			}
			client, err := NewClient(c)
			So(err, ShouldBeNil)

			err = client.BindRoute("7803de15-a20f-4dea-bf17-37de56629582", "ce5d0e27-3048-4024-80cb-fafbae9c3161")
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldStartWith, "Error binding route 7803de15-a20f-4dea-bf17-37de56629582 to app ce5d0e27-3048-4024-80cb-fafbae9c3161")
		})
	})
}

func TestDeleteRoute(t *testing.T) {
	Convey("Delete route", t, func() {
		Convey("When a successful status code is returned", func() {
			setup(MockRoute{"DELETE", "/v2/routes/a537761f-9d93-4b30-af17-3d73dbca181b", "", "", 204, "", nil}, t)
			defer teardown()
			c := &Config{
				ApiAddress: server.URL,
				Token:      "foobar",
			}
			client, err := NewClient(c)
			So(err, ShouldBeNil)

			err = client.DeleteRoute("a537761f-9d93-4b30-af17-3d73dbca181b")
			So(err, ShouldBeNil)
		})

		Convey("When an error status code is returned", func() {
			setup(MockRoute{"DELETE", "/v2/routes/a537761f-9d93-4b30-af17-3d73dbca181b", "", "", 404, "", nil}, t)
			defer teardown()
			c := &Config{
				ApiAddress: server.URL,
				Token:      "foobar",
			}
			client, err := NewClient(c)
			So(err, ShouldBeNil)

			err = client.DeleteRoute("a537761f-9d93-4b30-af17-3d73dbca181b")
			So(err, ShouldNotBeNil)
		})
	})
}
