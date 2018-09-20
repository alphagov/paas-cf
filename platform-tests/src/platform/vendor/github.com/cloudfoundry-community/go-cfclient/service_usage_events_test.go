package cfclient

import (
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListServiceUsageEvents(t *testing.T) {
	Convey("List Service Usage Events", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/service_usage_events", listServiceUsageEventsPayload, "", 200, "", nil},
			{"GET", "/v2/service_usage_eventsPage2", listServiceUsageEventsPayloadPage2, "", 200, "results-per-page=2&page=2", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		serviceUsageEvents, err := client.ListServiceUsageEvents()
		So(err, ShouldBeNil)

		So(len(serviceUsageEvents), ShouldEqual, 4)
		So(serviceUsageEvents[0].GUID, ShouldEqual, "985c09c5-bf5a-44eb-a260-41c532dc0f1d")
		So(serviceUsageEvents[0].CreatedAt, ShouldEqual, "2016-06-08T16:41:39Z")
	})
}

func TestListServiceUsageEventsByQuery(t *testing.T) {
	Convey("List Service Usage Events", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/service_usage_events", listServiceUsageEventsPayload, "", 200, "results-per-page=2", nil},
			{"GET", "/v2/service_usage_eventsPage2", listServiceUsageEventsPayloadPage2, "", 200, "results-per-page=2&page=2", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		var query = url.Values{
			"results-per-page": []string{
				"2",
			},
		}
		serviceUsageEvents, err := client.ListServiceUsageEventsByQuery(query)
		So(err, ShouldBeNil)

		So(len(serviceUsageEvents), ShouldEqual, 4)
		So(serviceUsageEvents[0].GUID, ShouldEqual, "985c09c5-bf5a-44eb-a260-41c532dc0f1d")
		So(serviceUsageEvents[0].CreatedAt, ShouldEqual, "2016-06-08T16:41:39Z")
	})
}
