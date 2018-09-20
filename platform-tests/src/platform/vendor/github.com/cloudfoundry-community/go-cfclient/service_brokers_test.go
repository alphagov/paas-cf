package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServiceBrokers(t *testing.T) {
	Convey("List Service Brokers", t, func() {
		setup(MockRoute{"GET", "/v2/service_brokers", listServiceBrokersPayload, "", 200, "", nil}, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		servicePlans, err := client.ListServiceBrokers()
		So(err, ShouldBeNil)

		So(len(servicePlans), ShouldEqual, 1)
		So(servicePlans[0].Guid, ShouldEqual, "90a413fd-a636-4133-8bfb-a94b07839e96")
		So(servicePlans[0].Name, ShouldEqual, "name-85")
		So(servicePlans[0].BrokerURL, ShouldEqual, "https://foo.com/url-2")
		So(servicePlans[0].Username, ShouldEqual, "auth_username-2")
		So(servicePlans[0].SpaceGUID, ShouldEqual, "1d43e64d-ed64-43dd-9046-11f422bd407b")
		So(servicePlans[0].Password, ShouldBeEmpty)
	})
}
