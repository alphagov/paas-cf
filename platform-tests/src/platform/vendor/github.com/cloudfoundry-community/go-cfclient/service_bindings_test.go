package cfclient

import (
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
