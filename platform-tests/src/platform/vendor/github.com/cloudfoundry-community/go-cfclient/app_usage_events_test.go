package cfclient

import (
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestListAppUsageEvents(t *testing.T) {
	Convey("List App Usage Events", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/app_usage_events", listAppUsageEventsPayload, "", 200, "", nil},
			{"GET", "/v2/app_usage_eventsPage2", listAppUsageEventsPayloadPage2, "", 200, "results-per-page=2&page=2", nil},
		}
		setupMultiple(mocks, t)
		defer teardown()
		c := &Config{
			ApiAddress: server.URL,
			Token:      "foobar",
		}
		client, err := NewClient(c)
		So(err, ShouldBeNil)

		appUsageEvents, err := client.ListAppUsageEvents()
		So(err, ShouldBeNil)

		So(len(appUsageEvents), ShouldEqual, 4)
		So(appUsageEvents[0].GUID, ShouldEqual, "b32241a5-5508-4d42-893c-360e42a300b6")
		So(appUsageEvents[0].CreatedAt, ShouldEqual, "2016-06-08T16:41:33Z")
	})
}

func TestListAppUsageEventsByQuery(t *testing.T) {
	Convey("List App Usage Events", t, func() {
		mocks := []MockRoute{
			{"GET", "/v2/app_usage_events", listAppUsageEventsPayload, "", 200, "results-per-page=2", nil},
			{"GET", "/v2/app_usage_eventsPage2", listAppUsageEventsPayloadPage2, "", 200, "results-per-page=2&page=2", nil},
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
		appUsageEvents, err := client.ListAppUsageEventsByQuery(query)
		So(err, ShouldBeNil)

		So(len(appUsageEvents), ShouldEqual, 4)
		So(appUsageEvents[0].GUID, ShouldEqual, "b32241a5-5508-4d42-893c-360e42a300b6")
		So(appUsageEvents[0].CreatedAt, ShouldEqual, "2016-06-08T16:41:33Z")
	})
}
