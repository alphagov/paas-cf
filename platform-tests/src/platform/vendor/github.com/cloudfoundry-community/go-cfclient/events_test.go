package cfclient

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListEvents(t *testing.T) {
	Convey("List Events", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/events", listEventsPage1Payload, "", 200, "", nil},
			{"GET", "/v2/events-2", listEventsPage2Payload, "", 200, "page=2", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		events, err := client.ListEvents()
		So(err, ShouldBeNil)

		So(len(events), ShouldEqual, 4)
		So(events[0].GUID, ShouldEqual, "b8ede8e1-afc8-40a1-baae-236a0a77b27b")
		So(events[0].Actor, ShouldEqual, "guid-008640fc-d316-4602-9251-c8d09bbdc750")
		So(events[0].CreatedAt, ShouldEqual, "2016-06-08T16:41:23Z")
	})
}

func TestTotalEvents(t *testing.T) {
	Convey("Total Events", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/events", totalEventsPayload, "", 200, "", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		total, err := client.TotalEvents()
		So(err, ShouldBeNil)

		So(total, ShouldEqual, 4)
	})
}
