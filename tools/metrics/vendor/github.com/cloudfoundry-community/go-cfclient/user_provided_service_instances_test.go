package cfclient

import (
	"reflect"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestUserProvidedServiceInstanceByGuid(t *testing.T) {
	Convey("Service instance by Guid", t, func() {
		setup(MockRoute{"GET", "/v2/user_provided_service_instances/e9358711-0ad9-4f2a-b3dc-289d47c17c87", userProvidedServiceInstancePayload, "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		instance, err := client.GetUserProvidedServiceInstanceByGuid("e9358711-0ad9-4f2a-b3dc-289d47c17c87")
		So(err, ShouldBeNil)

		So(instance.Guid, ShouldEqual, "e9358711-0ad9-4f2a-b3dc-289d47c17c87")
		So(reflect.DeepEqual(
			instance.Credentials,
			map[string]interface{}{"creds-key-58": "creds-val-58"}), ShouldBeTrue)
		So(instance.Name, ShouldEqual, "name-1700")
		So(instance.SpaceGuid, ShouldEqual, "22236d1a-d9c7-44b7-bdad-2bb079a6c4a1")
		So(instance.RouteServiceUrl, ShouldEqual, "")
		So(instance.Type, ShouldEqual, "user_provided_service_instance")
		So(instance.SpaceUrl, ShouldEqual, "/v2/spaces/22236d1a-d9c7-44b7-bdad-2bb079a6c4a1")
		So(instance.SyslogDrainUrl, ShouldEqual, "https://foo.com/url-104")
		So(instance.ServiceBindingsUrl, ShouldEqual, "/v2/user_provided_service_instances/e9358711-0ad9-4f2a-b3dc-289d47c17c87/service_bindings")
		So(instance.RoutesUrl, ShouldEqual, "/v2/user_provided_service_instances/e9358711-0ad9-4f2a-b3dc-289d47c17c87/routes")
	})
}

func TestListUserProvidedServiceInstances(t *testing.T) {
	Convey("List Service Instances", t, func() {
		setup(MockRoute{"GET", "/v2/user_provided_service_instances", listUserProvidedServiceInstancePayload, "", 200, "", nil}, t)
		defer teardown()

		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		instances, err := client.ListUserProvidedServiceInstances()
		So(err, ShouldBeNil)

		instance := instances[0]
		So(instance.Guid, ShouldEqual, "54e4c645-7d20-4271-8c27-8cc904e1e7ee")
		So(reflect.DeepEqual(
			instance.Credentials,
			map[string]interface{}{"creds-key-57": "creds-val-57"}), ShouldBeTrue)
		So(instance.Name, ShouldEqual, "name-1696")
		So(instance.SpaceGuid, ShouldEqual, "87d14ac2-f396-460e-a523-dc1d77aba35a")
		So(instance.RouteServiceUrl, ShouldEqual, "")
		So(instance.Type, ShouldEqual, "user_provided_service_instance")
		So(instance.SpaceUrl, ShouldEqual, "/v2/spaces/87d14ac2-f396-460e-a523-dc1d77aba35a")
		So(instance.SyslogDrainUrl, ShouldEqual, "https://foo.com/url-103")
		So(instance.ServiceBindingsUrl, ShouldEqual, "/v2/user_provided_service_instances/54e4c645-7d20-4271-8c27-8cc904e1e7ee/service_bindings")
		So(instance.RoutesUrl, ShouldEqual, "/v2/user_provided_service_instances/54e4c645-7d20-4271-8c27-8cc904e1e7ee/routes")
	})
}
