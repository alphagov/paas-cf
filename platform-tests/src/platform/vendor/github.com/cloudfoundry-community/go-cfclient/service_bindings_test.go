package cfclient

import (
	"net/http"
	"reflect"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServiceBindings(t *testing.T) {
	Convey("List Service Bindings", t, func() {
		setup(MockRoute{"GET", "/v2/service_bindings", listServiceBindingsPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceBindings, err := client.ListServiceBindings()
		So(err, ShouldBeNil)

		So(len(serviceBindings), ShouldEqual, 1)
		So(serviceBindings[0].Guid, ShouldEqual, "aa599bb3-4811-405a-bbe3-a68c7c55afc8")
		So(serviceBindings[0].AppGuid, ShouldEqual, "b26e7e98-f002-41a8-a663-1b60f808a92a")
		So(serviceBindings[0].ServiceInstanceGuid, ShouldEqual, "bde206e0-1ee8-48ad-b794-44c857633d50")
		So(reflect.DeepEqual(
			serviceBindings[0].Credentials,
			map[string]interface{}{"creds-key-66": "creds-val-66"}), ShouldBeTrue)
		So(serviceBindings[0].BindingOptions, ShouldBeEmpty)
		So(serviceBindings[0].GatewayData, ShouldBeNil)
		So(serviceBindings[0].GatewayName, ShouldEqual, "")
		So(serviceBindings[0].SyslogDrainUrl, ShouldEqual, "")
		So(serviceBindings[0].VolumeMounts, ShouldBeEmpty)
		So(serviceBindings[0].AppUrl, ShouldEqual, "/v2/apps/b26e7e98-f002-41a8-a663-1b60f808a92a")
		So(serviceBindings[0].ServiceInstanceUrl, ShouldEqual, "/v2/service_instances/bde206e0-1ee8-48ad-b794-44c857633d50")
	})
}
func TestServiceBindingByGuid(t *testing.T) {
	Convey("Service Binding By Guid", t, func() {
		setup(MockRoute{"GET", "/v2/service_bindings/foo-bar-baz", serviceBindingByGuidPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceBinding, err := client.GetServiceBindingByGuid("foo-bar-baz")
		So(err, ShouldBeNil)

		So(serviceBinding.Guid, ShouldEqual, "foo-bar-baz")
		So(serviceBinding.AppGuid, ShouldEqual, "app-bar-baz")
	})
}

func TestDeleteServiceBinding(t *testing.T) {
	Convey("Delete service binding", t, func() {
		setup(MockRoute{"DELETE", "/v2/service_bindings/guid", "", "", http.StatusNoContent, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.DeleteServiceBinding("guid")
		So(err, ShouldBeNil)
	})
}

func TestCreateServiceBinding(t *testing.T) {
	Convey("Create service binding", t, func() {
		body := `{"app_guid":"app-guid","service_instance_guid":"service-instance-guid"}`
		setup(MockRoute{"POST", "/v2/service_bindings", postServiceBindingPayload, "", http.StatusCreated, "", &body}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		binding, err := client.CreateServiceBinding("app-guid", "service-instance-guid")
		So(err, ShouldBeNil)
		So(binding.Guid, ShouldEqual, "4e690cd4-66ef-4052-a23d-0d748316f18c")
		So(binding.AppGuid, ShouldEqual, "081d55a0-1bfa-4e51-8d08-273f764988db")
		So(binding.ServiceInstanceGuid, ShouldEqual, "a0029c76-7017-4a74-94b0-54a04ad94b80")
	})
}

func TestCreateRouteServiceBinding(t *testing.T) {
	Convey("Create route service binding", t, func() {
		setup(MockRoute{"PUT", "/v2/user_provided_service_instances/5badd282-6e07-4fc6-a8c4-78be99040774/routes/237d9236-7997-4b1a-be8d-2aaf2d85421a", "", "", http.StatusCreated, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		err = client.CreateRouteServiceBinding("237d9236-7997-4b1a-be8d-2aaf2d85421a", "5badd282-6e07-4fc6-a8c4-78be99040774")
		So(err, ShouldBeNil)
	})
}
