package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServices(t *testing.T) {
	Convey("List Services", t, func() {
		setup(MockRoute{"GET", "/v2/services", listServicePayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		services, err := client.ListServices()
		So(err, ShouldBeNil)

		So(len(services), ShouldEqual, 2)
		So(services[0].Guid, ShouldEqual, "a3d76c01-c08a-4505-b06d-8603265682a3")
		So(services[0].Label, ShouldEqual, "nats")
		So(services[0].Description, ShouldEqual, "NATS is a lightweight cloud messaging system")
		So(services[0].Active, ShouldEqual, true)
		So(services[0].Bindable, ShouldEqual, true)
		So(services[0].PlanUpdateable, ShouldEqual, false)
		So(services[1].ServiceBrokerGuid, ShouldEqual, "a4bdf03a-f0c4-43f9-9c77-f434da91404f")
		So(services[1].Guid, ShouldEqual, "ab9ad9c8-1f51-463a-ae3a-5082e9f04ae6")
		So(services[1].Label, ShouldEqual, "etcd")
		So(services[1].Description, ShouldEqual, "Etcd key-value storage")
		So(services[1].Active, ShouldEqual, true)
		So(services[1].Bindable, ShouldEqual, true)
		So(services[1].PlanUpdateable, ShouldEqual, false)
		So(services[1].ServiceBrokerGuid, ShouldEqual, "a4bdf03a-f0c4-43f9-9c77-f434da91404f")
		So(len(services[1].Tags), ShouldEqual, 3)
		So(services[1].Tags[0], ShouldEqual, "etcd")
		So(services[1].Tags[1], ShouldEqual, "keyvalue")
		So(services[1].Tags[2], ShouldEqual, "etcd-0.4.6")
	})
}

func TestGetServiceByGuid(t *testing.T) {
	Convey("Get Service By Guid", t, func() {
		setup(MockRoute{"GET", "/v2/services/53f52780-e93c-4af7-a96c-6958311c40e5", getServiceByGuidPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		service, err := client.GetServiceByGuid("53f52780-e93c-4af7-a96c-6958311c40e5")
		So(err, ShouldBeNil)

		So(service.Guid, ShouldEqual, "53f52780-e93c-4af7-a96c-6958311c40e5")
		So(service.Label, ShouldEqual, "label-58")
		So(service.Description, ShouldEqual, "desc-135")
		So(service.Active, ShouldEqual, true)
		So(service.Bindable, ShouldEqual, true)
		So(service.PlanUpdateable, ShouldEqual, false)
	})
}
